require 'csv'
require 'activerecord-import'
require 'parallel'

def sqlite3_table_import_cmd(db, occurrences_tsv)
  <<~HEREDOC
  sqlite3 #{db} <<EOF
  .mode tabs
  .import #{occurrences_tsv} occurrences
  EOF
  HEREDOC
end

namespace :pipeline do
  desc "filter out invalid or duplicate occurrences"
  task filter_occurrences: :environment do
    OccurrenceRecord.each_occurrence_slice_grouped_by_accession(STDIN) do |occurrences|
      OccurrenceRecord.filter(occurrences).each do |occurrence|
        puts occurrence.to_str
      end
    end
  end

  desc "add occurrences to database"
  task add_occurrences: :environment do
    # chunks = 0

    species_hash = {}

    tsv = Tempfile.new
    csv = CSV.new(tsv, col_sep: "\t")

    idx = 0

    OccurrenceRecord.each_occurrence_slice_grouped_by_path(STDIN) do |chunk|
      row = chunk.first
      species_path = row[0]

      if species_hash.has_key?(species_path)
        species = species_hash[species_path]
      else
        species_hash[species_path] = Species.find_or_create_by(path: species_path) do |species|
          species.taxon_kingdom = row[5]
          species.taxon_phylum = row[6]
          species.taxon_class = row[7]
          species.taxon_order = row[8]
          species.taxon_family = row[9]
          species.taxon_genus = row[10]
          species.taxon_species = row[11]
          species.taxon_subspecies = row[12]

          # FIXME: move different_genbank_species to species
          # species.different_genbank_species = row[17]
        end

        species = species_hash[species_path]
      end

      chunk.each do |row|
        idx += 1
        # 0 is last argument for source gbif
        csv << [idx, row[1], row[2], row[3], row[4], row[13], row[14], row[15].to_s.to_i, row[16], row[17], species.id, 0]
      end

      # TODO:
      # # ha we need path to add files (but can avoid it right now :-P)
      # Occurrence.import(chunk.map { |row|
      #   {
      #     species_id: species.id,
      #     accession: row[1],
      #     gbif_id: row[2],
      #     lat: row[3],
      #     lng:  row[4],
      #     basis_of_record: row[13],
      #     geodetic_datum: row[14],
      #     # FIXME: .to_s.to_i => check to see if we should coerce to 0 or nil or if
      #     # these were accidentally all coerced to 0 previously
      #     coordinate_uncertainty_in_meters: row[15].to_s.to_i,
      #     issue: row[16],
      #     different_genbank_species: row[17]
      #   }
      # })

      # chunks += 1
    end

    # now do import
    system(sqlite3_table_import_cmd(ActiveRecord::Base.connection.instance_variable_get(:@config)[:database], tsv.path))
  ensure
    tsv.close
    tsv.unlink
  end

  desc "add bold records to database"
  task add_bold_records: :environment do
    # STDIN has all the bold records
  end

  desc "align fasta files"
  task align: :environment do
    #FIXME: this currently does not parallelize the work and instead does all the work sequentially
    files = Species.write_alignment_files_from_cache(Species.files_needing_alignment)

    workers = files.count >= 27 ? Parallel.physical_processor_count-1 : 0
    puts "Parallel.each over files with in_processes: #{workers}"

    Parallel.each(files, in_processes: workers) do |file|
      puts "aligning #{file}"
      Species.align_file file
    end
  end

  desc "align fasta files using parallel command processor"
  task alignpcp: :environment do
    files = Species.write_alignment_files_from_cache(Species.files_needing_alignment)
    commands = files.map {|f| "./align_sequences.sh #{f.to_s}"}.join("\n") + "\n"
    puts Open3.capture2('mpiexec','parallel-command-processor', stdin_data: commands)
  end

  desc "delete all fasta alignment files"
  task :clobber_alignments do
    rm_f Rake::FileList[Configuration.genbank_root.join('**/*\.afa')]
  end

  desc "update Species metrics"
  task update_species_metrics: :environment do
    # Species.where(aligned: false).each(&:update_metrics!)
    Species.find_each(&:update_metrics!)
  end

  desc "update Species metrics that are flagged as not aligned"
  task update_unaligned_species_metrics: :environment do
    Species.where(aligned: false).each(&:update_metrics!)
  end

end
