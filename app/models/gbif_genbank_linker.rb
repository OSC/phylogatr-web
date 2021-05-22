class GbifGenbankLinker

  class GenbankRecord
    attr_reader :record
    def initialize(record)
      @record = record
    end
  end

  class Gene
    attr_reader :feature, :record, :occurrence
    delegate :gbif_id, :accession, to: :occurrence

    def self.product_symbol_mappings
      @product_symbol_mappings ||= Hash[Rails.root.join('pipeline', 'product_symbol_lookup.tsv').read.strip.split("\n").map {|l|
        l.split("\t")
      }]
    end

    def initialize(feature, record, occurrence)
      @feature = feature
      @record = record
      @occurrence = occurrence
    end

    def fasta_file_path
      if symbol.present?
        File.join(occurrence.species_path, fasta_file_prefix)
      else
        ''
      end
    end

    def fasta_file_prefix
      "#{occurrence.taxon_species}-#{symbol}".gsub(' ', '-')
    end

    def sequence
      record.seq.splicing(feature.position).to_s.downcase
    end

    def species
      record.organism.gsub(/\//, ' ')
    end

    def species_different_from_occurrence
      species if species != occurrence.taxon_species
    end

    def qualifiers
      @qualifiers ||= feature.to_hash
    end

    def name
      qualifiers['product']&.first.to_s.gsub(/[ \/ ]/, '-').gsub(/['\.]/, '')
    end

    def original_symbol
      qualifiers['gene']&.first.to_s.gsub(/[ \/ ]/, '-').gsub(/['\.]/, '').upcase
    end

    def symbol
      @symbol ||= self.class.product_symbol_mappings.fetch(name, original_symbol)
    end

    def valid?
      symbol.present?
    end
  end

  class Sequence
    attr_reader :genbank_record
    attr_reader :gbif_records

    delegate :accession, to: :genbank_record

    # this also has occurrences and genes method that
    # handles duplicates and validations etc.

    def initialize(genbank_record, gbif_records)
      @genbank_record = genbank_record
      @gbif_records = gbif_records # OccurrenceRecord
    end

    def genes
      @genes ||= begin
        if occurrences.present?
          list = []
          genbank_record.each_cds do |feature|
            g = Gene.new(feature, genbank_record, occurrences.first)
            list << g if g.valid?
          end
          list
        else
          []
        end
      end
    end

    # filter may get rid of all valid occurrences, in which case we ignore this sequence
    def occurrences
      @occurrences ||= OccurrenceRecord.filter(gbif_records)
    end

    def species_different_from_occurrence
      genes.first&.species_different_from_occurrence
    end
  end

  # gbif tsv io object ordered by accession
  # genbank flat file format ordered by accession
  def initialize(gbif, genbank)
    @gbif = gbif
    @genbank = genbank
  end

  # iterator works like this:
  # tab delimited io
  # GbifRecord GenbankRecord
  #
  #
  # each_valid_sequence(gbif_path, gb_path) do |sequence|
  #   sequence.genes.each do |gene|
  #     genes.write(gene.to_str)
  #   end
  #   sequence.occurrences.each do |occurrence|
  #     occurrences.write(occurrence.to_str)
  #   end
  # end
  #

  #
  # index is an array of [[ACCESSION, BYTEPOS],[ACCESSION, BYTEPOS], ...]
  # FIXME: as an optimization, this could be extracted out and/or memoized
  # though memoization would need to use `@gbif_indexes ||= Hash.new do |h, key| pattern` otherwise
  # tests will fail; but this takes around 2 seconds to run and when parallelized over 28-48 cores
  # even if running 560+ times (one per genbank file) it adds only a minute to the walltime
  #
  def self.build_gbif_index(gbif)
    gbif_index = []

    File.open(gbif) do |f|
      f.each_line.with_index do |line, index|
        gbif_index << [OccurrenceRecord.from_str(line).accession, f.pos]  if index % 50000 == 0
      end
    end

    gbif_index
  end

  def self.seek_closer_to_starting_accession!(gbif, accession)
    gbif_index = build_gbif_index(gbif)

    pos = ((accession && gbif_index.reverse_each.find {|i| i.first < accession}) || [0,0]).last

    gbif.seek(pos, IO::SEEK_SET)
  end

  # NOTE: this method assumes:
  #
  # 1. genbank flat file will have only 1 record per accession
  # 2. gbif tsv may have multiple records per accession
  # 3. genbank and gbif accessions are capitalized
  #
  def each
    return to_enum(:each) unless block_given?

    File.open(@gbif) do |gbifio|
      File.open(@genbank) do |genbankio|
        gbif_enum = OccurrenceRecord.each_occurrence_slice_grouped_by_accession(gbifio)
        records = gbif_enum.next

        ff = Bio::GenBank.open(genbankio)
        ff.each_with_index do |entry, index|
          if index == 0
            self.class.seek_closer_to_starting_accession!(gbifio, entry.accession) unless records.first&.accession == entry.accession
          end

          until records.first&.accession >= entry.accession do
            records = gbif_enum.next
          end

          if records.first.accession == entry.accession
            yield Sequence.new(entry, records)
          end
        end

      rescue StopIteration => e
        # noop - end of the enumeration
      end
    end
  end

  def self.write_genes_and_occurrences(gbif_path, genbank_path, out_genes_path, out_occurrences_path)
    gbif_file = File.open(gbif_path)
    genbank_file = File.open(genbank_path)
    out_genes_file = File.open(out_genes_path, 'w')
    out_occurrences_file = File.open(out_occurrences_path, 'w')

    GbifGenbankLinker.new(gbif_file, genbank_file).each do |sequence|
      if sequence.occurrences.present? && sequence.genes.present?
        sequence.genes.each do |gene|
          out_genes_file.write([
            gene.fasta_file_path,
            gene.accession,
            gene.symbol,
            gene.name,
            gene.fasta_file_prefix,
            gene.species,
            File.basename(genbank_path.to_s),
            gene.sequence,
            gene.gbif_id
          ].join("\t") + "\n")
        end

        sequence.occurrences.each do |occurrence|
          out_occurrences_file.write(occurrence.to_post_str(sequence.species_different_from_occurrence, sequence.genes.map(&:symbol).sort.uniq.join(" "))+ "\n")
        end
      end
    end
  ensure
    gbif_file.close
    genbank_file.close
    out_genes_file.close
    out_occurrences_file.close
  end
end
