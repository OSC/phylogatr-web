require 'rubygems/package'

class SearchResults
  attr_reader :swpoint, :nepoint, :taxonomy

  def self.write_tar_to_file(params, path, uinfo_path = nil)
    Pathname.new(path).tap { |d| d.dirname.mkpath }.open('wb') do |f|
      SearchResults.from_params(params).write_tar(f, uinfo_path)
    end
  end

  def self.write_zip_to_file(params, path, uinfo_path = nil)
    Pathname.new(path).tap { |d| d.dirname.mkpath }.open('wb') do |f|
      SearchResults.from_params(params).write_zip(
        ZipTricks::BlockWrite.new { |chunk| f.write(chunk)  },
        uinfo_path
      )
    end
  end

  # FIXME: filtering the key value pairs we can pass on
  # belongs in controller...
  def self.clean_params(params)
    (params || {}).symbolize_keys.select do |k,v|
      ([
      :southwest_corner_latitude,
      :southwest_corner_longitude,
      :northeast_corner_latitude,
      :northeast_corner_longitude,
      :results_format
      ].include?(k) || k.to_s.starts_with?("taxon_")) && v.present?
    end
  end

  def self.from_params(params)
    params = clean_params(params)
    swpoint = [params[:southwest_corner_latitude], params[:southwest_corner_longitude]]
    nepoint = [params[:northeast_corner_latitude], params[:northeast_corner_longitude]]
    taxonomy = params.select {|k,v| k.to_s.starts_with?("taxon_") && v.present? }

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
    info.num_species
  end


  def estimated_tar_size
    info.estimated_tar_size
  end

  def info
    @info ||= SearchResultsInfo.build(swpoint, nepoint, taxonomy)
  end

  # TODO: pass block to capture progress messages (??) for progress messages
  # yield(message, percentage)
  #
  # summary query (so we will group by)
  def write_tar(file, uinfo_path = nil)


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

        species = Species.in_bounds_with_taxonomy(swpoint, nepoint, taxonomy)

        uinfo = SearchResultsInfo::FileUpdater.load(uinfo_path, species.count)
        uinfo.wrote_fasta_files(0)

        #
        # 50% at 5% intervals 20 species  10 groups or 189 species every 189/10
        # -- every 18
        # % 18
        # but every 18 you want to increase percent by 5 :-P
        #
        # also need to know the "index"
        # which is hard to know below
        #
        species.each_with_index do |s, index|
          s.files.each do |file|
            tar_file_path = File.join('phylogatr-results', file.relative_path_from(Configuration.genbank_root))
            tar.add_file_simple(tar_file_path, 0644, file.size) do |tar_file|
              Rails.logger.debug "adding tar file: #{tar_file_path}"
              File.open(file) do |fasta_file|
                Rails.logger.debug "wrote to tar bytes: #{IO.copy_stream(fasta_file, tar_file)}"
              end
            end

            uinfo.wrote_fasta_files(index+1)
          end
        end

        # write each species
        #
        # writing occurrences file (how much?)
        #
        # writing genes file
        #
        # completed! 100%
        #
        # ActiveModel does it have more methods for this type of thing?
        # just how much time does each part take?
        # write occurrences file for each species
        #
        # puts 'write occurrences file', Benchmark.measure {

        # FIXME: this uses more memory but is simpler
        # will use far less if we reduce what we write to these files
        species.each_slice(500).with_index do |subset, subset_index|
          if swpoint.all?(&:present?) && nepoint.all?(&:present?)
            occurrences = Occurrence.joins(:species).where(species_id: subset.map(&:id)).in_bounds([swpoint, nepoint]).select('occurrences.*, species.path').order('species.path')
          else
            occurrences = Occurrence.joins(:species).where(species_id: subset.map(&:id)).select('occurrences.*, species.path').order('species.path')
          end

          occurrences.group_by(&:path).each_with_index { |(species_path, occurrences), index|
            bytesize = occurrences.sum { |o| o.to_str.length }+Occurrence.headers_tsv.length
            tar.add_file_simple(File.join('phylogatr-results', species_path, 'occurrences.txt'), 0644, bytesize) do |io|
              # write headers
              io.write(Occurrence.headers_tsv)
              # write occurrences
              occurrences.each do |o|
                io.write(o.to_str)
              end
            end

            uinfo.wrote_occurrence_file(subset_index*500+index+1)
          }
        end

        # } # Benchmark.measure {

        uinfo.done

        genes_index_str = Species.genes_index_headers_tsv + species.map(&:genes_index_str).sort.join

        tar.add_file_simple(File.join('phylogatr-results', 'genes.txt'), 0644, genes_index_str.length) do |io|
          io.write(genes_index_str)
        end
      end
    end
  end

  def write_zip(file, uinfo_path = nil)
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

      #
      # we used to have a search Occurrence.in_bounds_with_taxonomy
      # thats why we put the taxonomy duplicates in Occurrences
      # otherwise the joins was expensive
      #
      species = Species.in_bounds_with_taxonomy(swpoint, nepoint, taxonomy).order(:path)
      uinfo = SearchResultsInfo::FileUpdater.load(uinfo_path, species.count)
      uinfo.wrote_fasta_files(0)

      species.each_with_index do |s, index|
        s.files.each do |file|
          tar_file_path = File.join('phylogatr-results', file.relative_path_from(Configuration.genbank_root))
          zip.write_deflated_file(tar_file_path) do |tar_file|
            Rails.logger.debug "adding tar file: #{tar_file_path}"
            File.open(file) do |fasta_file|
              Rails.logger.debug "wrote to tar bytes: #{IO.copy_stream(fasta_file, tar_file)}"
            end
          end
        end

        uinfo.wrote_fasta_files(index+1)
      end

      # FIXME: this uses more memory but is simpler
      # will use far less if we reduce what we write to these files
      species.each_slice(500).with_index do |subset, subset_index|
        if swpoint.all?(&:present?) && nepoint.all?(&:present?)
          occurrences = Occurrence.joins(:species).where(species_id: subset.map(&:id)).in_bounds([swpoint, nepoint]).select('occurrences.*, species.path').order('species.path')
        else
          occurrences = Occurrence.joins(:species).where(species_id: subset.map(&:id)).select('occurrences.*, species.path').order('species.path')
        end

        occurrences.group_by(&:path).each_with_index { |(species_path, occurrences), index|
          zip.write_deflated_file(File.join('phylogatr-results', species_path, 'occurrences.txt')) do |io|
            # write headers
            io.write(Occurrence.headers_tsv)
            # write occurrences
            occurrences.each do |o|
              io.write(o.to_str)
            end
          end

          uinfo.wrote_occurrence_file(subset_index*500+index+1)
        }
      end

      uinfo.done

      zip.write_deflated_file(File.join('phylogatr-results', 'genes.txt')) do |io|
        io.write(Species.genes_index_headers_tsv)
        io.write(species.map(&:genes_index_str).sort.join)
      end
    end
  end
end
