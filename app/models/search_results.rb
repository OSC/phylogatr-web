class SearchResults
  attr_reader :swpoint, :nepoint, :taxonomy

  def self.from_params(params)
    swpoint = [params[:southwest_corner_latitude], params[:southwest_corner_longitude]]
    nepoint = [params[:northeast_corner_latitude], params[:northeast_corner_longitude]]
    taxonomy = params.select {|k,v| k.starts_with?("taxon_") && v.present? }.symbolize_keys

    self.new(swpoint, nepoint, taxonomy)
  end

  def initialize(swpoint, nepoint, taxonomy)
    @swpoint = swpoint
    @nepoint = nepoint
    @taxonomy = taxonomy
  end

  # summary query (so we will group by)
  def write_tar(file)
    Zlib::GzipWriter.wrap(file) do |gz|
      Gem::Package::TarWriter.new(gz) do |tar|
        # Note: cannot use find-each because that uses primary key and limit and
        # offset and its own sort by primary key so it ignores sort order we
        # want

        cite_yaml = {
          gbif_doi: '10.35000/cdl.t4hfxk',
          genbank_release: 'GenBank Flat File Release 234.0',
          phylogatr_code_version: 'd609767'
        }.stringify_keys.to_yaml

        tar.add_file_simple("phylogatr-results/cite.txt", 0644, cite_yaml.length) do |io|
          io.write(cite_yaml)
        end

        current_sequences = []
        current_prefix = nil
        current_species = nil

        # Gene is really a gene_sequence
        Gene.find_each_in_bounds_with_taxonomy(swpoint, nepoint, taxonomy) do |gene|
          current_prefix ||= gene.fasta_file_prefix
          current_species ||= gene.taxon_species.gsub(' ', '-')

          if(gene.fasta_file_prefix != current_prefix)
            # new file so we write out the current first
            tar.add_file_simple("phylogatr-results/#{current_species}/#{current_prefix}.fa", 0644, current_sequences.sum { |s| s.to_fasta.length }) do |io|
              current_sequences.each do |s|
                io.write(s.to_fasta)
              end
            end

            tar.add_file_simple("phylogatr-results/#{current_species}/#{current_prefix}.afa", 0644, current_sequences.sum { |s| s.to_aligned_fasta.length }) do |io|
              current_sequences.each do |s|
                io.write(s.to_aligned_fasta)
              end
            end

            current_sequences = [gene]
            current_prefix = gene.fasta_file_prefix
            current_species = gene.taxon_species.gsub(' ', '-')
          else
            #FIXME: better to add count of sequence (and thus FASTA) here to speed things up (instead of memoizing fasta and sequence which balloons memory)
            current_sequences << gene
          end
        end

        if current_sequences.any?
          tar.add_file_simple("phylogatr-results/#{current_species}/#{current_prefix}.fa", 0644, current_sequences.sum { |s| s.to_fasta.length }) do |io|
            current_sequences.each do |s|
              io.write(s.to_fasta)
            end
          end
          tar.add_file_simple("phylogatr-results/#{current_species}/#{current_prefix}.afa", 0644, current_sequences.sum { |s| s.to_aligned_fasta.length }) do |io|
            current_sequences.each do |s|
              io.write(s.to_aligned_fasta)
            end
          end
        end

        current_sequences = []


        current_occurrences = []
        current_species = nil

        # ordered by species
        Occurrence.find_each_in_bounds_with_taxonomy_joins_genes(swpoint, nepoint, taxonomy) do |occurrence|
          current_species ||= occurrence.taxon_species.gsub(' ', '-')

          if(occurrence.taxon_species.gsub(' ', '-') != current_species)
            # new file so we write out the current first
            tar.add_file_simple("phylogatr-results/#{current_species}/occurrences.txt", 0644, current_occurrences.sum { |o| o.to_str.length }) do |io|
              current_occurrences.each do |o|
                io.write(o.to_str)
              end
            end

            current_occurrences = [occurrence]
            current_species = occurrence.taxon_species.gsub(' ', '-')
          else
            current_occurrences << occurrence
          end
        end

        if current_occurrences.any?
          tar.add_file_simple("phylogatr-results/#{current_species}/occurrences.txt", 0644, current_occurrences.sum { |o| o.to_str.length }) do |io|
            current_occurrences.each do |o|
              io.write(o.to_str)
            end
          end
        end
      end
    end
  end
end
