class SearchResults
  attr_reader :swpoint, :nepoint, :taxonomy

  def self.from_params(params)
    swpoint = [params['southwest_corner_latitude'], params['southwest_corner_longitude']]
    nepoint = [params['northeast_corner_latitude'], params['northeast_corner_longitude']]
    taxonomy = params.select {|k,v| k.starts_with?("taxon_") && v.present? }.symbolize_keys

    self.new(swpoint, nepoint, taxonomy)
  end

  # ordered by precendence, 0 lowest, 6 highest
  def taxonomic_ranks
    %w(kingdom phylum class order family genus species).map { |t| "taxon_#{t}".to_sym }
  end

  def reduce_taxonomy_to_one_constraint(tax)
    Hash[*((tax || {}).reject { |k,v|
      v.blank?
    }.max_by {|k, v|
      taxonomic_ranks.index(k)
    })]
  end

  def initialize(swpoint, nepoint, taxonomy)
    @swpoint = swpoint
    @nepoint = nepoint
    @taxonomy = reduce_taxonomy_to_one_constraint(taxonomy)
  end

  def to_s
    rank, taxon = taxonomy.each_pair.first
    taxon_summary = "#{rank.to_s.sub('taxon_', '').capitalize} #{taxon}"

    if swpoint.all?(&:present?) && nepoint.all?(&:present?) && taxonomy.present?
      "#{taxon_summary} in bounds southwest #{swpoint} to northeast #{nepoint}"
    elsif swpoint.all?(&:present?) && nepoint.all?(&:present?)
      "All in bounds southwest #{swpoint} to northeast #{nepoint}"
    elsif taxonomy.present?
      "#{taxon_summary}"
    else
      "All"
    end
  end

  def params
    {
      southwest_corner_latitude: swpoint[0],
      southwest_corner_longitude: swpoint[1],
      northeast_corner_latitude: nepoint[0],
      northeast_corner_longitude: nepoint[1]
    }.merge(taxonomy)
  end

  def download_limit
    1024*1024*1024
  end

  def num_species
    # FIXME: species table
    # FIXME: taxon_species is preferred to use once fixing pipeline issue
    Occurrence.in_bounds_with_taxonomy(swpoint, nepoint, taxonomy).distinct.count(:species_path)
  end

  # TODO:
  # def seqs_per_species
  #   # FIXME: species table
  #   Occurrence.in_bounds_with_taxonomy(swpoint, nepoint, taxonomy)
  #     .select(:species_path, :species_total_seqs).distinct.as_json
  # end

  def estimated_tar_size
    Occurrence.from(
      Occurrence.in_bounds_with_taxonomy(swpoint, nepoint, taxonomy)
       .where.not(species_total_bytes: nil)
       .distinct
       .select(:species_path, :species_total_bytes)
    ).sum('subquery.species_total_bytes')
  end

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

        #FIXME: ask for another db to setup tests
        #FIXME: add to metrics a json field with cached summary of file sizes
        # for writing tarballs faster, if we continue to use Ruby
        # FIXME: pulling everyting down in 1 query...

        species_paths = Occurrence.in_bounds_with_taxonomy(swpoint, nepoint, taxonomy).distinct.pluck(:species_path)
        species_paths.each do |species_path|
          Species.new(Configuration.genbank_root.join(species_path)).files.each do |file|
            tar_file_path = File.join('phylogatr-results', file.relative_path_from(Configuration.genbank_root))
            tar.add_file_simple(tar_file_path, 0644, file.size) do |tar_file|
              Rails.logger.debug "adding tar file: #{tar_file_path}"
              File.open(file) do |fasta_file|
                Rails.logger.debug "wrote to tar bytes: #{IO.copy_stream(fasta_file, tar_file)}"
              end
            end
          end
        end

        genes_index = StringIO.new
        genes_index.write(Species.genes_index_headers_tsv)

        # FIXME: this uses more memory but is simpler
        # will use far less if we reduce what we write to these files
        species_paths.each_slice(500) do |subset|
          Occurrence.in_bounds_with_taxonomy(swpoint, nepoint, taxonomy)
            .where(species_path: subset)
            .order(:species_path)
            .group_by(&:species_path).each { |species_path, occurrences|


              bytesize = occurrences.sum { |o| o.to_str.length }+Occurrence.headers_tsv.length
              tar.add_file_simple(File.join('phylogatr-results', species_path, 'occurrences.txt'), 0644, bytesize) do |io|
                # write headers
                io.write(Occurrence.headers_tsv)
                # write occurrences
                occurrences.each do |o|
                  io.write(o.to_str)
                end
              end

              genes_index.write(occurrences.first.species.genes_index_str(occurrences.first))
          }
        end

        tar.add_file_simple(File.join('phylogatr-results', 'genes.txt'), 0644, genes_index.size) do |io|
          io.write(genes_index.string)
        end
      end
    end
  end

  def write_zip(file)
    ZipTricks::Streamer.open(file) do |zip|
      # Note: cannot use find-each because that uses primary key and limit and
      # offset and its own sort by primary key so it ignores sort order we
      # want

      #TODO:
      cite_yaml = {
        gbif_doi: '10.35000/cdl.t4hfxk',
        genbank_release: 'GenBank Flat File Release 234.0',
        phylogatr_code_version: Configuration.app_version
      }.stringify_keys.to_yaml

      zip.write_deflated_file("phylogatr-results/cite.txt") do |io|
        io.write(cite_yaml)
      end

      #FIXME: ask for another db to setup tests
      #FIXME: add to metrics a json field with cached summary of file sizes
      # for writing tarballs faster, if we continue to use Ruby
      # FIXME: pulling everyting down in 1 query...

      species_paths = Occurrence.in_bounds_with_taxonomy(swpoint, nepoint, taxonomy).distinct.pluck(:species_path)
      species_paths.each do |species_path|
        Species.new(Configuration.genbank_root.join(species_path)).files.each do |file|
          tar_file_path = File.join('phylogatr-results', file.relative_path_from(Configuration.genbank_root))
          zip.write_deflated_file(tar_file_path) do |tar_file|
            Rails.logger.debug "adding tar file: #{tar_file_path}"
            File.open(file) do |fasta_file|
              Rails.logger.debug "wrote to tar bytes: #{IO.copy_stream(fasta_file, tar_file)}"
            end
          end
        end
      end

      genes_index = StringIO.new
      genes_index.write(Species.genes_index_headers_tsv)

      # FIXME: this uses more memory but is simpler
      # will use far less if we reduce what we write to these files
      species_paths.each_slice(500) do |subset|
        Occurrence.in_bounds_with_taxonomy(swpoint, nepoint, taxonomy)
          .where(species_path: subset)
          .order(:species_path)
          .group_by(&:species_path).each { |species_path, occurrences|


            zip.write_deflated_file(File.join('phylogatr-results', species_path, 'occurrences.txt')) do |io|
              # write headers
              io.write(Occurrence.headers_tsv)
              # write occurrences
              occurrences.each do |o|
                io.write(o.to_str)
              end
            end

            genes_index.write(occurrences.first.species.genes_index_str(occurrences.first))
        }
      end

      zip.write_deflated_file(File.join('phylogatr-results', 'genes.txt')) do |io|
          io.write(genes_index.string)
      end
    end
  end
end
