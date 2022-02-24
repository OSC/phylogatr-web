# frozen_string_literal: true

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
  desc 'expand GBIF GBIF_OUT '
  task 'expand_gbif_occurrences_on_accession' do
    raise 'required: GBIF GBIF_OUT' unless ENV['GBIF'] && ENV['GBIF_OUT']

    GbifGenbankLinker.expand_gbif_occurrences_on_accession(ENV['GBIF'], ENV['GBIF_OUT'])
  end

  desc 'bold taxonomies'
  task bold_taxons: :environment do
    taxons = BoldRecord.taxonomies('https://www.boldsystems.org/index.php/TaxBrowser_Home')

    # print out API URLs?!
    taxons.sort_by(&:category).each do |t|
      puts "#{t.category}: #{t.name}"
    end
  end

  desc 'link gbif with genbank'
  task :link_gbif_with_genbank do
    unless ENV['GBIF_PATH_EXPANDED'] && ENV['OUTPUT_DIR'] && ENV['GENBANK_PATH']
      raise 'required: GBIF_PATH_EXPANDED OUTPUT_DIR'
    end

    genbank_path = ENV['GENBANK_PATH']
    output_dir = ENV['OUTPUT_DIR']

    puts "linking #{ENV['GBIF_PATH_EXPANDED']} with #{genbank_path}"

    basepath = File.join(output_dir, File.basename(genbank_path))
    genes_out = "#{basepath}.genes.tsv"
    gbif_out = "#{basepath}.genes.tsv.occurrences"

    GbifGenbankLinker.write_genes_and_occurrences(ENV['GBIF_PATH_EXPANDED'], genbank_path, genes_out, gbif_out)

    puts "done linking #{ENV['GBIF_PATH_EXPANDED']} with #{genbank_path}"
  end

  desc 'link all gbif with genbank'
  task link_all_gbif_with_genbank: :environment do
    # execute with rake -m to parallelize
    unless ENV['GENBANK_DIR'] && ENV['GBIF_PATH_EXPANDED'] && ENV['OUTPUT_DIR']
      raise 'required: GBIF_PATH_EXPANDED GENBANK_DIR OUTPUT_DIR'
    end

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
        genes_out = "#{basepath}.genes.tsv"
        gbif_out = "#{basepath}.genes.tsv.occurrences"

        GbifGenbankLinker.write_genes_and_occurrences(ENV['GBIF_PATH_EXPANDED'], genbank_path, genes_out, gbif_out)

        puts "done linking #{ENV['GBIF_PATH_EXPANDED']} with #{genbank_path}"
      end
    end

    task :link_all => genbank_files

    Rake::Task[:link_all].invoke
  end

  desc 'filter out invalid or duplicate occurrences'
  task filter_occurrences: :environment do
    OccurrenceRecord.each_occurrence_slice_grouped_by_accession($stdin) do |occurrences|
      OccurrenceRecord.filter(occurrences).each do |occurrence|
        puts occurrence.to_str
      end
    end
  end

  desc 'add occurrences to database'
  task add_occurrences: :environment do
    # chunks = 0

    species_hash = {}

    tsv = Tempfile.new
    csv = CSV.new(tsv, col_sep: "\t")

    idx = 0

    using_mysql_adapter = ActiveRecord::Base.connection.adapter_name == 'Mysql2'
    using_sqlite_adapter = ActiveRecord::Base.connection.adapter_name == 'SQLite'

    h = {}
    OccurrenceRecord::POST_HEADERS.each_with_index { |column, index| h[column] = index }

    OccurrenceRecord.each_occurrence_slice_grouped_by_path($stdin) do |chunk|
      row = chunk.first
      species_path = row[h[:species_path]]

      different_genbank_species = row[h[:different_genbank_species]].presence

      if species_hash.key?(species_path)
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
    if using_sqlite_adapter
      system(sqlite3_table_import_cmd(ActiveRecord::Base.connection.instance_variable_get(:@config)[:database],
                                      tsv.path))
    elsif using_mysql_adapter
      ActiveRecord::Base.connection.execute(%(load data local infile "#{tsv.path}" into table occurrences;))
    else
      raise 'Unkown adapter for importing occurrences'
    end
  ensure
    tsv.close
    tsv.unlink
  end

  desc 'filter out invalid or duplicate bold records'
  task filter_bold_records: :environment do
    files = Dir.glob("#{ENV['FILTERED_BOLD_DIR']}/x*").reject { |p| File.extname(p) == '.filtered' }

    totals = Parallel.map(files) do |file|
      puts "reading file #{file}"
      invalid_records = duplicate_records = 0

      records = CSV.read(file, col_sep: "\t", headers: BoldRecord::HEADERS)
      input_records = records.size

      all = records.map do |record|
        BoldRecord.new(record.to_h)
      end.select do |record|
        invalid_records += 1 unless record.valid?
        record.valid?
      end.reject do |record|
        duplicate_records += 1 if record.duplicate?
        record.duplicate?
      end

      File.open("#{file}.filtered", 'w+') do |output_file|
        all.each do |record|
          output_file.puts(record.to_tsv)
        end
      end

        {
          'input_records' => input_records,
          'output_records' => all.size,
          'invalid_records' => invalid_records,
          'duplicate_records' => duplicate_records
        }
    end.each_with_object({}) do |entry, total|
      total['input_records'] = entry['input_records'] + (total['input_records'] || 0)
      total['output_records'] = entry['output_records'] + (total['output_records'] || 0)
      total['invalid_records'] = entry['invalid_records'] + (total['invalid_records'] || 0)
      total['duplicate_records'] = entry['duplicate_records'] + (total['duplicate_records'] || 0)
    end

    PipelineMetrics.append_record(totals.merge({ 'name' => 'filter_bold_records' }))
  end

  desc 'add bold records to database'
  task add_bold_records: :environment do
    if ENV['BOLD_ROOT'].nil? || !File.directory?(ENV['BOLD_ROOT'])
      raise "#{ENV['BOLD_ROOT']} set in BOLD_ROOT environment variable is invalid!"
    end

    kingdoms = {
      'Acanthocephala'  => 'Animalia',
      'Annelida'        => 'Animalia',
      'Arthropoda'      => 'Animalia',
      'Ascomycota'      => 'Fungi',
      'Basidiomycota'   => 'Fungi',
      'Brachiopoda'     => 'Animalia',
      'Bryophyta'       => 'Plantae',
      'Bryozoa'         => 'Animalia',
      'Chaetognatha'    => 'Animalia',
      'Chlorophyta'     => 'Plantae',
      'Chordata'        => 'Animalia',
      'Ciliophora'      => 'Chromista',
      'Cnidaria'        => 'Animalia',
      'Ctenophora'      => 'Animalia',
      'Echinodermata'   => 'Animalia',
      'Mollusca'        => 'Animalia',
      'Nematoda'        => 'Animalia',
      'Nematomorpha'    => 'Animalia',
      'Nemertea'        => 'Animalia',
      'Platyhelminthes' => 'Animalia',
      'Porifera'        => 'Animalia',
      'Rhodophyta'      => 'Plantae',
      'Rotifera'        => 'Animalia',
      'Sipuncula'       => 'Animalia',
      'Tardigrada'      => 'Animalia',
      'Zygomycota'      => 'Fungi',
      'Chytridiomycota' => 'Fungi',
      'Entoprocta'      => 'Animalia',
      'Gastrotricha'    => 'Animalia',
      'Glomeromycota'   => 'Fungi',
      'Kinorhyncha'     => 'Animalia',
      'Lycopodiophyta'  => 'Plantae',
      'Magnoliophyta'   => 'Plantae',
      'Phoronida'       => 'Animalia',
      'Pinophyta'       => 'Plantae',
      'Priapulida'      => 'Animalia',
      'Pteridophyta'    => 'Plantae'
    }

    files = Dir.glob("#{ENV['BOLD_ROOT']}/*.tsv")
    totals = Parallel.map(files) do |file|
      invalid_records = invalid_taxons = invalid_occurences = output_files = input_records = 0

      CSV.foreach(file, col_sep: "\t", headers: BoldRecord::HEADERS) do |line|
        # read line by line so we can catch and skip individual malformed rows
        begin
          input_records += 1
          record = BoldRecord.new(**line.to_h)
        rescue StandardError => e
          invalid_records += 1
          puts "#{e.class} #{e.message}"
          next
        end

        # TODO: every skipped record should be written to a file
        unless record.gene_symbol_mapped.present? && record.sequence.present? && record.species.present? && record.species_binomial?
          invalid_records += 1
          next
        end

        # FIXME: be careful of case issues
        # FIXME: cache species to reduce the number of queries?
        species = Species.find_by(taxon_species: record.species)
        taxons_set = ['phylum', 'class', 'order', 'family', 'genus', 'species'].all? do |t|
          record.send(:"taxon_#{t}").present?
        end

        unless species || (taxons_set && kingdoms.include?(record.taxon_phylum))
          invalid_taxons += 1
          next
        end

        if species.nil?
          species = Species.create(
            path:          File.join(record.taxon_class, record.taxon_order, record.taxon_family,
                                     record.species.gsub(' ', '-')),
            taxon_kingdom: kingdoms[record.taxon_phylum],
            taxon_phylum:  record.taxon_phylum,
            taxon_class:   record.taxon_class,
            taxon_order:   record.taxon_order,
            taxon_family:  record.taxon_family,
            taxon_genus:   record.taxon_genus,
            taxon_species: record.species,
            aligned:       false
          )
        end

        occurrence = Occurrence.new(
          source:         :bold,
          source_id:      record.process_id,
          catalog_number: record.catalog_number.presence,
          field_number:   record.field_number.presence,
          accession:      record.accession.presence,
          lat:            record.lat,
          lng:            record.lng,
          species_id:     species.id,
          genes:          record.gene_symbol_mapped
        )

        unless occurrence.save
          invalid_occurences += 1
          next
        end

        # Reptilia/Squamata/Agamidae/Phrynocephalus-persicus/Phrynocephalus-persicus-COI
        fname = "#{record.species}-#{record.gene_symbol_mapped.upcase}".gsub(' ', '-')
        fasta_path = "#{Configuration.genbank_root.join(species.path, fname)}.fa"

        # occurrence saved, now write gene data
        FileUtils.mkdir_p(File.dirname(fasta_path))

        File.write(fasta_path, record.fasta_sequence, mode: 'a+')

        output_files += 1

        species.update(aligned: false) if species.aligned
      end

      {
        'input_records' => input_records,
        'invalid_records' => invalid_records,
        'invalid_taxons' => invalid_taxons,
        'invalid_occurences' => invalid_occurences,
        'output_files' => output_files
      }
    end.each_with_object({}) do |entry, total|
      total['input_records'] = entry['input_records'] + (total['input_records'] || 0)
      total['invalid_records'] = entry['invalid_records'] + (total['invalid_records'] || 0)
      total['invalid_taxons'] = entry['invalid_taxons'] + (total['invalid_taxons'] || 0)
      total['invalid_occurences'] = entry['invalid_occurences'] + (total['invalid_occurences'] || 0)
      total['output_files'] = entry['output_files'] + (total['output_files'] || 0)
    end

    PipelineMetrics.append_record(totals.merge({ 'name' => 'add_bold_records' }))
  end

  desc 'align fasta files'
  task align: :environment do
    # FIXME: this currently does not parallelize the work and instead does all the work sequentially
    files = Species.write_alignment_files_from_cache(Species.files_needing_alignment)

    workers = files.count >= 27 ? Parallel.physical_processor_count - 1 : 0
    puts "Parallel.each over files with in_processes: #{workers}"

    Parallel.each(files, in_processes: workers) do |file|
      puts "aligning #{file}"
      Species.align_file file
    end
  end

  desc 'align fasta files using parallel command processor'
  task alignpcp: :environment do
    files_needing_alignment = Species.files_needing_alignment
    files = Species.write_alignment_files_from_cache(files_needing_alignment)
    timeout = ENV['TIMEOUT'] ? "timeout #{ENV['TIMEOUT']}" : ''

    puts "#{files_needing_alignment.count - files.count} alignments written from cache"
    puts "aligning #{files.count} files"

    commands = files.map { |f| "time #{timeout} ./align_sequences.sh #{Shellwords.escape(f)}" }
    commands_path = File.join(ENV['TMPDIR'], 'commands')
    File.open(commands_path, 'w+') do |f|
      f.puts(commands)
    end

    nproc = `nproc`.strip.to_i - 1
    exec "srun -n #{nproc} --export=ALL parallel-command-processor #{commands_path}"
  end

  desc 'delete all fasta alignment files'
  task :clobber_alignments do
    rm_f Rake::FileList[Configuration.genbank_root.join('**/*\.afa')]
  end

  desc 'update Species metrics'
  task update_species_metrics: :environment do
    workers = `nproc`.strip.to_i
    count = Species.count

    limit = count / workers

    # support for serial if there's only 1 processor allocated
    if workers == 1
      Species.all.each(&:update_metrics!)
    else
      Parallel.each(1..workers, :in_processes => workers) do |_i|
        # execute once per worker - would it be easier to just fork?
        offset = limit * Parallel.worker_number

        # worker number starts at 0, so if last worker, want to get rest of records
        limit = count - offset if Parallel.worker_number == workers - 1
        Species.limit(limit).offset(offset).each(&:update_metrics!)
      end
    end
  end

  desc 'update Species metrics that are flagged as not aligned'
  task update_unaligned_species_metrics: :environment do
    Species.where(aligned: false).each(&:update_metrics!)
  end

  desc 'delete species and occurrences that have 0 or few sequences'
  task clean_db: :environment do
    # first delete all fasta files that have only 1 or 2 sequences
    # this call update_metrics on each modified Species
    Species.find_each(&:delete_files_with_few_sequences)

    # then delete all the Species that have 0 sequences
    Species.where(total_seqs: 0).find_each { |s| s.occurrences.delete_all }
    Species.where(total_seqs: 0).delete_all
  end
end
