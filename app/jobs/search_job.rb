require 'rubygems/package'

class SearchJob < ActiveJob::Base
  queue_as :default

  # in_bounds_with_taxonomy.count # so we know the maximum
  def perform(path, swpoint, nepoint, taxonomy)
    tarball_path = Pathname.new(path).join("phylogatr-results.tar.gz")
    tarball_path.parent.mkpath

    # TODO: instead of making 1 tarball, we would want to expand to multiple for
    # a large search
    # so refactor this to write tarball
    # (passing in the Gene.joins.merge.where.not.order.distinct relation to call find_each on)
    #
    # the problem with this code is its complex to read

    tarball_path.open("wb") do |file|
      # FIXME: gzip is non-seekable so we need to get the content length if we
      # will write the files; which means a new strategy, such as building the
      # list of all of the sequences for an individual file before writing them
      # to the tarball might be required, as then we can determine the filesize
      # but that is memory intensive and not performant
      # maybe doing a single large request and streaming it is preferred to
      # chunking the request, or sorting by file fasta prefix and then accession
      # prior to generation of primary keys indices for genes
      #
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
end
