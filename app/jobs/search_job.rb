require 'rubygems/package'

class SearchJob < ActiveJob::Base
  queue_as :default

  # in_bounds_with_taxonomy.count # so we know the maximum
  def perform(path, swpoint, nepoint, taxonomy)
    tarball_path = Pathname.new(path).join("phylogatr-results.tar")
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
      # Zlib::GzipWriter.wrap(file) do |gz|

      Gem::Package::TarWriter.new(file) do |tar|
        # Note: cannot use find-each because that uses primary key and limit and
        # offset and its own sort by primary key so it ignores sort order we
        # want
        gene_enumerator = Gene.find_each_in_bounds_with_taxonomy(swpoint, nepoint, taxonomy)

        tar.add_file("phylogatr-results/cite.txt", 0644) do |io|
          io.write({
            gbif_doi: '10.35000/cdl.t4hfxk',
            genbank_release: 'GenBank Flat File Release 234.0',
            phylogatr_code_version: 'd609767'
          }.to_yaml)
        end

        loop do
          # keep writing files till this me
          write_genes_to_tar_file gene_enumerator, tar
        end
      end
    end
  end

  # pass in an enmerator, and add sequence of each gene to a new file in the
  # tarball till we hit the last item in the enumerator or we get to a new file
  def write_genes_to_tar_file(gene_enumerator, tar)
    prefix = gene_enumerator.peek.fasta_file_prefix
    #FIXME: HACK we substitute ' ' for '-' as we do in the pipeline.py
    # we might consider generating this as well when running the pipeline for
    # convenience, or using the join table to generate both of these on the fly
    # instead
    species = gene_enumerator.peek.taxon_species.gsub(' ', '-')

    tar.add_file("phylogatr-results/#{species}/#{prefix}.fa", 0644) do |io|
      begin
        while gene_enumerator.peek.fasta_file_prefix == prefix
          io.write(gene_enumerator.next.to_fasta)
        end
      rescue => e
        # ignore StopIteration when its inside this block, otherwise the file
        # will not be properly closed and contents written
        #
        # StopIteration will be emitted in this block only if the file stops
        # reading
      end
    end
  end
end
