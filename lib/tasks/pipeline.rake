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
  desc "bold taxonomies"
  task bold_taxons: :environment do
    taxons = BoldRecord.taxonomies('https://www.boldsystems.org/index.php/TaxBrowser_Home')

    # print out API URLs?!
    taxons.sort_by(&:category).each do |t|
      puts "#{t.category}: #{t.name}"
    end
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
        #
        #FIXME: row[14] is geodetic_datum which is dropped in the future for now...
        if(using_mysql_adapter)
          csv << [idx, row[1], row[2], row[3], row[4], row[13], row[14].presence || '\N', row[15].to_s.to_i, row[16], row[17], species.id, 0]
        else
          csv << [idx, row[1], row[2], row[3], row[4], row[13], row[14], row[15].to_s.to_i, row[16], row[17], species.id, 0]
        end
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

  desc "add bold records to database"
  task add_bold_records: :environment do
    # After bold data is downloaded from BOLD website using API
    # cat the files together and execute this to produce the simple version:
    #
    # cut -d $'\t' -f1,3,4,5,10,12,14,16,20,22,24,47,48,70,71,72 $TMPDIR/bold.tsv > $TMPDIR/bold.simple.tsv
    #
    #
    #
    #
    # FIXME: could use BoldRecord class

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

    # we need taxon_species => [id, path]
    # TODO:
    # after you confirm it works...
    # species_names = Set.new(Species.pluck(:taxon_species))
    # could cache the few species we get, by "species" so we don't do another query...

    fasta_files_updated = Set.new

    csv.each do |row|
      record = BoldRecord.new(**row.to_h)
      next unless record.gene_symbol_mapped.present? && record.sequence.present?

      # FIXME: be careful of case issues
      species = Species.find_by(taxon_species: record.taxon_species)
      taxons_set = %w(phylum class order family genus species).all? {|t| record.send(:"taxon_#{t}").present? }

      if species || (taxons_set && kingdoms.include?(record.taxon_phylum))
        if species.nil?
          species = Species.create(
            path: File.join(record.taxon_class, record.taxon_order, record.taxon_family, record.taxon_species.gsub(' ', '-')),
            taxon_kingdom: kingdoms[record.taxon_phylum],
            taxon_phylum: record.taxon_phylum,
            taxon_class: record.taxon_class,
            taxon_order: record.taxon_order,
            taxon_family: record.taxon_family,
            taxon_genus: record.taxon_genus,
            taxon_species: record.taxon_species,
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
          species_id: species.id
        )

        if ! occurrence.duplicate? && occurrence.save
          # Reptilia/Squamata/Agamidae/Phrynocephalus-persicus/Phrynocephalus-persicus-COI
          fasta_path = Configuration.genbank_root.join(species.path, "#{record.taxon_species}-#{record.gene_symbol_mapped.upcase}").to_s.gsub(' ', '-') + ".fa"

          # occurrence saved, now write gene data
          FileUtils.mkdir_p(File.dirname(fasta_path))
          File.write(fasta_path, record.fasta_sequence, mode: "a+")

          fasta_files_updated << fasta_path

          species.update(aligned: false) if species.aligned
        end
      end # if species || (taxons_set && kingdoms.include?(record.taxon_phylum))
    # else
      #TODO: species not found and taxons not set - make note of this - as we could fill in taxonomy if we had more info
    end

    # remove and print to stderr the fasta_files that have fewer than 3 sequences
    # the number of sequences is == number lines / 2
    fasta_files_updated.each do |path|
      # FIXME: 3 is this magic threshold
      count = BoldRecord.line_count(path)
      if(BoldRecord.line_count(path) < 3)
        $stderr.puts "#{path} has only #{count} lines"

        File.unlink path
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
    files = Species.write_alignment_files_from_cache(Species.files_needing_alignment)
    commands = files.map {|f| "./align_sequences.sh #{f.to_s}"}.join("\n") + "\n"
    puts Open3.capture2('srun','parallel-command-processor', stdin_data: commands)
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

  desc "update extra fields"
  task update_extra_fields: :environment do
    # FIXME: this will take like 10 hours or more
    #
    # created by taking raw gbif data, filtered, and filtering again like:
    # xsv select -d '\t' 1,2,16,17,18,19 occurrence_filtered.txt.simplified > occurrence_filtered.txt.simplified.new_fields
    #
    # time awk -F$'\t' 'BEGIN {OFS = FS} { print $1 $2 $16 $17 $18 $19 }' occurrence_filtered.txt.simplified > occurrence_filtered.txt.simplified.new_fields
    #
    # where
    #
    # 0  1   associatedSequences
    # 1  2   gbifID
    # 2  16  fieldNumber
    # 3  17  catalogNumber
    # 4  18  identifier
    # 5  19  eventDate
    #
    # since xsv outputs commas
    csv = CSV.new(STDIN, col_sep: "\t")
    csv.each do |row|
      row[0].scan(/\w{2}\d{6}/).each do |accession|

        source_id = row[1]
        field_number = row[2].presence
        catalog_number = row[3].presence

        identifier = row[4].presence

        # BOLD process ids look like GBAN19261-19
        unless identifier =~ /^[a-zA-Z0-9]+-\d+$/
          identifier = nil
        end

        event_date = nil
        begin
          event_date = row[5].strip.present? ? row[5].to_date : nil
        rescue
        end

        begin
          Occurrence.where(accession: accession, source_id: source_id).update_all(field_number: field_number, catalog_number: catalog_number, identifier: identifier, event_date: event_date)
        rescue
          puts "Error for #{accession}, #{source_id}, #{catalog_number}, #{identifier}, #{event_date.inspect} date parsed from #{row[5]}"
        end
      end
    end
  end
end
