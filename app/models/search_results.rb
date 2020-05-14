class SearchResults
  attr_reader :swpoint, :nepoint, :taxonomy

  def self.from_params(params)
    swpoint = [params['southwest_corner_latitude'], params['southwest_corner_longitude']]
    nepoint = [params['northeast_corner_latitude'], params['northeast_corner_longitude']]
    taxonomy = params.select {|k,v| k.starts_with?("taxon_") && v.present? }.symbolize_keys

    self.new(swpoint, nepoint, taxonomy)
  end

  def initialize(swpoint, nepoint, taxonomy)
    @swpoint = swpoint
    @nepoint = nepoint
    @taxonomy = taxonomy
  end

  def params
    {
      southwest_corner_latitude: swpoint[0],
      southwest_corner_longitude: swpoint[1],
      northeast_corner_latitude: nepoint[0],
      northeast_corner_longitude: nepoint[1]
    }.merge(taxonomy)
  end

  def num_seqs
    @num_seqs ||= Gene.in_bounds_with_taxonomy(swpoint, nepoint, taxonomy).count
  end

  def download_limit
    20*1024*1024
  end

  def estimated_tar_size
    # total number of bytes + accession, >, and newlines
    num_bytes.values.map(&:to_i).reduce(&:+) + num_seqs*2*11
  end

  def num_seqs_per_file
    Gene.in_bounds_with_taxonomy(swpoint, nepoint, taxonomy)
        .group(:fasta_file_prefix)
        .count
  end

  def num_bytes
    @num_bytes ||= Gene.from(
      Gene.in_bounds_with_taxonomy(swpoint, nepoint, taxonomy)
          .select('genes.accession')
          .select('length(sequence) as sequence_length')
          .select('length(sequence_aligned) as aligned_length')
    ).select('SUM(sequence_length) AS total_sequences_length, SUM(aligned_length) AS total_aligned_length')
     .as_json
     .first
  end

  def num_bytes_sequences_aligned
    Gene.from(Gene.in_bounds_with_taxonomy(s, n, {taxon_genus: 'Pantherophis'}).select('genes.accession, length(sequence_aligned) as seqlengths')).sum('seqlengths')
  end

  # FIXME: the sum here did not work and was returning the wrong results
  #
  # def summary
  #   Gene.in_bounds_with_taxonomy(swpoint, nepoint, taxonomy)
  #       .group(:fasta_file_prefix)
  #       .select('count(distinct(genes.id)) as num_seqs')
  #       .select('sum(length(genes.sequence)) as fa_length')
  #       .select('sum(length(genes.sequence_aligned)) as afa_length')
  #       .select(:fasta_file_prefix)
  #       .as_json
  #       .map do |row|
  #         # FIXME: calcuating this length can be done in the query itself
  #         # with subquery
  #         # or even as a stored virtual column in MySQL
  #         #
  #         # Rails 5 supports keyword virtual and stored
  #         # https://github.com/rails/rails/commit/65bf1c60053e727835e06392d27a2fb49665484c
  #         #
  #         # the fa_length and afa_length omits the >, 2 newlines, and accession
  #         #
  #         # sqlite3 does support generated columns
  #         # https://sqlite.org/gencol.html but this is in 3.31.0 and we use only
  #         # 3.7 right now, switching to this would lose support for developing
  #         # against both databases
  #         offset = row['num_seqs']*11 # ACCESSON_LENGTH + 3 chars

  #         {
  #           'fasta_file_prefix' => row['fasta_file_prefix'],
  #           'count' => row['num_seqs'],
  #           'fa_length' => row['fa_length'] + offset,
  #           'afa_length' => row['afa_length'] + offset,
  #         }
  #       end
  # end
  def species_path(o)
    (File.join o.taxon_class, o.taxon_order, o.taxon_family, o.taxon_species).gsub(' ', '-')
  end

  # summary query (so we will group by)
  def write_tar(file)
    Zlib::GzipWriter.wrap(file) do |gz|
      Gem::Package::TarWriter.new(gz) do |tar|
        # Note: cannot use find-each because that uses primary key and limit and
        # offset and its own sort by primary key so it ignores sort order we
        # want

        #TODO:
        cite_yaml = {
          gbif_doi: '10.35000/cdl.t4hfxk',
          genbank_release: 'GenBank Flat File Release 234.0',
          phylogatr_code_version: Configuration.app_version
        }.stringify_keys.to_yaml

        tar.add_file_simple("phylogatr-results/cite.txt", 0644, cite_yaml.length) do |io|
          io.write(cite_yaml)
        end

        current_sequences = []
        current_prefix = nil
        current_species = nil
        current_species_dir = nil

        # Gene is really a gene_sequence
        Gene.find_each_in_bounds_with_taxonomy(swpoint, nepoint, taxonomy) do |gene|
          current_prefix ||= gene.fasta_file_prefix
          current_species ||= gene.taxon_species.gsub(' ', '-')
          current_species_dir ||= species_path(gene)

          if(gene.fasta_file_prefix != current_prefix)
            # new file so we write out the current first
            tar.add_file_simple("phylogatr-results/#{current_species_dir}/#{current_prefix}.fa", 0644, current_sequences.sum { |s| s.to_fasta.length }) do |io|
              current_sequences.each do |s|
                io.write(s.to_fasta)
              end
            end

            tar.add_file_simple("phylogatr-results/#{current_species_dir}/#{current_prefix}.afa", 0644, current_sequences.sum { |s| s.to_aligned_fasta.length }) do |io|
              current_sequences.each do |s|
                io.write(s.to_aligned_fasta)
              end
            end

            current_sequences = [gene]
            current_prefix = gene.fasta_file_prefix
            current_species = gene.taxon_species.gsub(' ', '-')
            current_species_dir = species_path(gene)
          else
            #FIXME: better to add count of sequence (and thus FASTA) here to speed things up (instead of memoizing fasta and sequence which balloons memory)
            current_sequences << gene
          end
        end

        if current_sequences.any?
          tar.add_file_simple("phylogatr-results/#{current_species_dir}/#{current_prefix}.fa", 0644, current_sequences.sum { |s| s.to_fasta.length }) do |io|
            current_sequences.each do |s|
              io.write(s.to_fasta)
            end
          end
          tar.add_file_simple("phylogatr-results/#{current_species_dir}/#{current_prefix}.afa", 0644, current_sequences.sum { |s| s.to_aligned_fasta.length }) do |io|
            current_sequences.each do |s|
              io.write(s.to_aligned_fasta)
            end
          end
        end

        current_sequences = []


        current_occurrences = []
        current_species = nil
        current_species_dir = nil

        # ordered by species
        Occurrence.find_each_in_bounds_with_taxonomy_joins_genes(swpoint, nepoint, taxonomy) do |occurrence|
          current_species ||= occurrence.taxon_species.gsub(' ', '-')
          current_species_dir ||= species_path(occurrence)

          if(occurrence.taxon_species.gsub(' ', '-') != current_species)
            # new file so we write out the current first
            tar.add_file_simple("phylogatr-results/#{current_species_dir}/occurrences.txt", 0644, current_occurrences.sum { |o| o.to_str.length }) do |io|
              current_occurrences.each do |o|
                io.write(o.to_str)
              end
            end

            current_occurrences = [occurrence]
            current_species = occurrence.taxon_species.gsub(' ', '-')
            current_species_dir = species_path(occurrence)
          else
            current_occurrences << occurrence
          end
        end

        if current_occurrences.any?
          tar.add_file_simple("phylogatr-results/#{current_species_dir}/occurrences.txt", 0644, current_occurrences.sum { |o| o.to_str.length }) do |io|
            current_occurrences.each do |o|
              io.write(o.to_str)
            end
          end
        end
      end
    end
  end
end
