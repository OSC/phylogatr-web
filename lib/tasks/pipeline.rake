require 'csv'
require 'activerecord-import'
require 'parallel'
require_relative '../../app/models/occurrence_record'
require_relative '../../app/models/gbif_genbank_linker'

def sqlite3_table_import_cmd(db, occurrences_tsv)
  <<~HEREDOC
  sqlite3 #{db} <<EOF
  .mode tabs
  .import #{occurrences_tsv} occurrences
  EOF
  HEREDOC
end

namespace :pipeline do
  desc "expand GBIF GBIF_OUT "
  task "expand_gbif_occurrences_on_accession" do
    raise "required: GBIF GBIF_OUT" unless ENV['GBIF'] && ENV['GBIF_OUT']

    GbifGenbankLinker.expand_gbif_occurrences_on_accession(ENV['GBIF'], ENV['GBIF_OUT'])
  end

  desc "bold taxonomies"
  task bold_taxons: :environment do
    taxons = BoldRecord.taxonomies('https://www.boldsystems.org/index.php/TaxBrowser_Home')

    # print out API URLs?!
    taxons.sort_by(&:category).each do |t|
      puts "#{t.category}: #{t.name}"
    end
  end

  desc "link gbif with genbank"
  task :link_gbif_with_genbank do
    raise "required: GBIF_PATH_EXPANDED OUTPUT_DIR" unless ENV['GBIF_PATH_EXPANDED'] && ENV['OUTPUT_DIR'] && ENV['GENBANK_PATH']
    genbank_path = ENV['GENBANK_PATH']
    output_dir = ENV['OUTPUT_DIR']

    puts "linking #{ENV['GBIF_PATH_EXPANDED']} with #{genbank_path}"

    basepath = File.join(output_dir, File.basename(genbank_path))
    genes_out = basepath+'.genes.tsv'
    gbif_out = basepath+'.genes.tsv.occurrences'

    GbifGenbankLinker.write_genes_and_occurrences(ENV['GBIF_PATH_EXPANDED'], genbank_path, genes_out, gbif_out)

    puts "done linking #{ENV['GBIF_PATH_EXPANDED']} with #{genbank_path}"
  end

  desc "link all gbif with genbank"
  task link_all_gbif_with_genbank: :environment do
    # execute with rake -m to parallelize
    raise "required: GBIF_PATH_EXPANDED GENBANK_DIR OUTPUT_DIR" unless ENV['GENBANK_DIR'] && ENV['GBIF_PATH_EXPANDED'] && ENV['OUTPUT_DIR']

    # GBIF_PATH_EXPANDED=/fs/project/PAS1604/gbif/0147211-200613084148143.filtered.txt.expanded
    # GENBANK_DIR=/fs/project/PAS1604/genbank
    # OUTPUT_DIR=/fs/scratch/PAS1604/genbank

    gbif_expanded = ENV['GBIF_PATH_EXPANDED']
    output_dir = ENV['OUTPUT_DIR']

    genbank_files = FileList[File.join(ENV['GENBANK_DIR'], 'gb{inv,mam,pln,pri,rod,vrt}*seq')]

    genbank_files.each do |genbank_path|
      task genbank_path do
        puts "linking #{ENV['GBIF_PATH_EXPANDED']} with #{genbank_path}"

        basepath = File.join(output_dir, File.basename(genbank_path))
        genes_out = basepath+'.genes.tsv'
        gbif_out = basepath+'.genes.tsv.occurrences'

        GbifGenbankLinker.write_genes_and_occurrences(ENV['GBIF_PATH_EXPANDED'], genbank_path, genes_out, gbif_out)

        puts "done linking #{ENV['GBIF_PATH_EXPANDED']} with #{genbank_path}"
      end
    end

    task :link_all => genbank_files

    Rake::Task[:link_all].invoke
  end

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

    using_mysql_adapter = ActiveRecord::Base.connection.adapter_name == 'Mysql2'
    using_sqlite_adapter = ActiveRecord::Base.connection.adapter_name == 'SQLite'

    h = {}
    OccurrenceRecord::POST_HEADERS.each_with_index {|column, index| h[column] = index }

    OccurrenceRecord.each_occurrence_slice_grouped_by_path(STDIN) do |chunk|
      row = chunk.first
      species_path = row[h[:species_path]]

      different_genbank_species = row[h[:different_genbank_species]].presence

      if species_hash.has_key?(species_path)
        species = species_hash[species_path]

        # HACK: this replicates the previous functionality of storing the
        # first "differeng genbanks species" string found but doesn't address
        # the case where some genes might not have accessions with a different
        # genbank species or when the number of records containing different
        # genbank species strings is greater than 1 (in some cases 70+
        # variations)
        if different_genbank_species && species.different_genbank_species.nil?
          species.different_genbank_species = different_genbank_species
          species.save
        end
      else
        species_hash[species_path] = Species.find_or_create_by(path: species_path) do |species|
          species.taxon_kingdom = row[h[:taxon_kingdom]]
          species.taxon_phylum = row[h[:taxon_phylum]]
          species.taxon_class = row[h[:taxon_class]]
          species.taxon_order = row[h[:taxon_order]]
          species.taxon_family = row[h[:taxon_family]]
          species.taxon_genus = row[h[:taxon_genus]]
          species.taxon_species = row[h[:taxon_species]]
          species.taxon_subspecies = row[h[:taxon_subspecies]]

          # HACK: see above HACK message for details
          species.different_genbank_species = different_genbank_species
        end

        species = species_hash[species_path]
      end

      chunk.each do |row|
        idx += 1
        csv << [
          idx,
          row[h[:accession]],
          row[h[:gbif_id]],
          row[h[:lat]],
          row[h[:lon]],
          OccurrencePostRecord.handle_null(row[h[:basis_of_record]]),
          row[h[:coordinate_uncertainty_in_meters]],
          OccurrencePostRecord.handle_null(row[h[:issue]]),
          OccurrencePostRecord.handle_null(row[h[:different_genbank_species]]),
          species.id,
          0,
          OccurrencePostRecord.handle_null(row[h[:field_number]]),
          OccurrencePostRecord.handle_null(row[h[:catalog_number]]),
          OccurrencePostRecord.handle_null(row[h[:identifier]]),
          row[h[:event_date]],
          row[h[:genes]],
          row[h[:flag]]
        ]
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
    if(using_sqlite_adapter)
      system(sqlite3_table_import_cmd(ActiveRecord::Base.connection.instance_variable_get(:@config)[:database], tsv.path))
    elsif(using_mysql_adapter)
      ActiveRecord::Base.connection.execute(%Q[load data local infile "#{tsv.path}" into table occurrences;])
    else
      raise "Unkown adapter for importing occurrences"
    end
  ensure
    tsv.close
    tsv.unlink
  end

  desc "filter out invalid or duplicate bold records"
  task filter_bold_records: :environment do
    STDIN.each_line do |line|
      begin
        # try to parse as CSV
        CSV.parse(line, col_sep: "\t", headers: BoldRecord::HEADERS)
        record = BoldRecord.from_str(line)

        if record.valid? && !record.duplicate?
          puts line
        end
      rescue => e
        $stderr.puts "#{e.class} #{e.message} when parsing line"
      end
    end
  end

  desc "add bold records to database"
  task add_bold_records: :environment do
    # Job array makes it easy cause then you can use the SAME
    # starting boldfile is an ARRAY and then the job array is just the index to get you that item
    #
    # For each files
    #
    # cp boldfile.tsv $TMPDIR/bold.tsv
    # cut -d $'\t' -f1,3,4,5,10,12,14,16,20,22,24,47,48,70,71,72 $TMPDIR/bold.tsv > $TMPDIR/bold.simple.tsv

    # STDIN has all the bold records
    # markercode is understood to be gene_symbol
    # nucleotides is understood to be sequence
    csv = CSV.new(STDIN, col_sep: "\t", headers: BoldRecord::HEADERS)


    kingdoms = {
      "Acanthocephala"=>"Animalia",
      "Annelida"=>"Animalia",
      "Arthropoda"=>"Animalia",
      "Ascomycota"=>"Fungi",
      "Basidiomycota"=>"Fungi",
      "Brachiopoda"=>"Animalia",
      "Bryophyta"=>"Plantae",
      "Bryozoa"=>"Animalia",
      "Chaetognatha"=>"Animalia",
      "Chlorophyta"=>"Plantae",
      "Chordata"=>"Animalia",
      "Ciliophora"=>"Chromista",
      "Cnidaria"=>"Animalia",
      "Ctenophora"=>"Animalia",
      "Echinodermata"=>"Animalia",
      "Mollusca"=>"Animalia",
      "Nematoda"=>"Animalia",
      "Nematomorpha"=>"Animalia",
      "Nemertea"=>"Animalia",
      "Platyhelminthes"=>"Animalia",
      "Porifera"=>"Animalia",
      "Rhodophyta"=>"Plantae",
      "Rotifera"=>"Animalia",
      "Sipuncula"=>"Animalia",
      "Tardigrada"=>"Animalia",
      "Zygomycota"=>"Fungi",

      "Chytridiomycota"=> 'Fungi',
      "Entoprocta"=> 'Animalia',
      "Gastrotricha"=> 'Animalia',
      "Glomeromycota"=> 'Fungi',
      "Kinorhyncha"=> 'Animalia',
      "Lycopodiophyta"=> 'Plantae',
      "Magnoliophyta"=> 'Plantae',
      "Phoronida"=>'Animalia',
      "Pinophyta"=>'Plantae',
      "Priapulida"=> 'Animalia',
      "Pteridophyta"=>'Plantae'
    }

    phylums_ignore = Set.new(%w(Chlorarachniophyta Heterokontophyta Lycopodiophyta Myxomycota Onychophora Pyrrophycophyta))

    fasta_files_updated = Set.new

    loop do
      # read line by line so we can catch and skip individual malformed rows
      record = nil
      begin
        row = csv.shift
        break unless row
        record = BoldRecord.new(**row.to_h)
      rescue => e
        puts "#{e.class} #{e.message}"
        next
      end

      # TODO: every skipped record should be written to a file
      next unless record.gene_symbol_mapped.present? && record.sequence.present? && record.species.present? && record.species_binomial?

      # FIXME: be careful of case issues
      # FIXME: cache species to reduce the number of queries?
      species = Species.find_by(taxon_species: record.species)
      taxons_set = %w(phylum class order family genus species).all? {|t| record.send(:"taxon_#{t}").present? }

      if species || (taxons_set && kingdoms.include?(record.taxon_phylum))
        if species.nil?
          species = Species.create(
            path: File.join(record.taxon_class, record.taxon_order, record.taxon_family, record.species.gsub(' ', '-')),
            taxon_kingdom: kingdoms[record.taxon_phylum],
            taxon_phylum: record.taxon_phylum,
            taxon_class: record.taxon_class,
            taxon_order: record.taxon_order,
            taxon_family: record.taxon_family,
            taxon_genus: record.taxon_genus,
            taxon_species: record.species,
            aligned: false
          )
        end

        occurrence = Occurrence.new(
          source: :bold,
          source_id: record.process_id,
          catalog_number: record.catalog_number.presence,
          field_number: record.field_number.presence,
          accession: record.accession.presence,
          lat: record.lat,
          lng: record.lng,
          species_id: species.id,
          genes: record.gene_symbol_mapped
        )

        if occurrence.save
          # Reptilia/Squamata/Agamidae/Phrynocephalus-persicus/Phrynocephalus-persicus-COI
          fasta_path = Configuration.genbank_root.join(species.path, "#{record.species}-#{record.gene_symbol_mapped.upcase}").to_s.gsub(' ', '-') + ".fa"

          # occurrence saved, now write gene data
          FileUtils.mkdir_p(File.dirname(fasta_path))

          File.write(fasta_path, record.fasta_sequence, mode: "a+")

          fasta_files_updated << fasta_path

          species.update(aligned: false) if species.aligned
        end
      end
    end
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
    files_needing_alignment = Species.files_needing_alignment
    files = Species.write_alignment_files_from_cache(files_needing_alignment)
    timeout = ENV['TIMEOUT'] ? "timeout #{ENV['TIMEOUT']}" : ""

    puts "#{files_needing_alignment.count - files.count} alignments written from cache"
    puts "aligning #{files.count} files"

    commands = files.map {|f| "time #{timeout} ./align_sequences.sh #{f.to_s}"}.join("\n") + "\n"

    commands_path = File.join(ENV['TMPDIR'], 'commands')
    File.write(commands_path, commands)

    exec "srun parallel-command-processor #{commands_path}"
  end

  desc "delete all fasta alignment files"
  task :clobber_alignments do
    rm_f Rake::FileList[Configuration.genbank_root.join('**/*\.afa')]
  end

  desc "update Species metrics"
  task update_species_metrics: :environment do
    workers = Parallel.physical_processor_count-1
    count = Species.count

    limit = count/workers

    Parallel.each(1..workers, :in_processes => workers) { |i|
      # execute once per worker - would it be easier to just fork?
      offset = limit * Parallel.worker_number

      # worker number starts at 0, so if last worker, want to get rest of records
      limit = count - offset if Parallel.worker_number == workers-1
      Species.limit(limit).offset(offset).each(&:update_metrics!)
    }
  end

  desc "update Species metrics that are flagged as not aligned"
  task update_unaligned_species_metrics: :environment do
    Species.where(aligned: false).each(&:update_metrics!)
  end

  desc "delete species and occurrences that have 0 or few sequences"
  task clean_db: :environment do
    # first delete all fasta files that have only 1 or 2 sequences
    # this call update_metrics on each modified Species
    Species.find_each {|s| s.delete_files_with_few_sequences }

    # then delete all the Species that have 0 sequences
    Species.where(total_seqs: 0).find_each {|s| s.occurrences.delete_all }
    Species.where(total_seqs: 0).delete_all
  end
end
