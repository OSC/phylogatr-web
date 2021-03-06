require 'shellwords'
require 'gdbm'
require 'digest'

class Species < ApplicationRecord
  has_many :occurrences

  def self.in_bounds_with_taxonomy(swpoint, nepoint, taxonomy)
    if swpoint.all?(&:present?) && nepoint.all?(&:present?)
      Species.joins(:occurrences).merge(Occurrence.in_bounds([swpoint, nepoint])).where(taxonomy).distinct.order(:path)
    else
      Species.where(taxonomy).order(:path)
    end
  end

  def self.taxons
    Species.where(aligned: true).pluck(:taxon_kingdom, :taxon_phylum, :taxon_class, :taxon_order, :taxon_family, :taxon_genus, :taxon_species)
  end

  Fasta = Struct.new(:seqs, :bytes, :prefix, :extension) do
    def aligned?
      extension == ".afa"
    end
    def unaligned?
      ! aligned?
    end
  end

  def absolute_path
    Configuration.genbank_root.join(path)
  end

  def self.line_and_byte_count(path, &block)
    # memoize the execution of the block based on the path
    # a gem (or ActiveSupport?) probably provides this though...
    @line_and_byte_counts ||= {}
    @line_and_byte_counts.fetch(path) do |path|
      counts = block.call(path)
      @line_and_byte_counts[path] = counts
      counts
    end
  end

  def line_and_byte_count(path)
    Species.line_and_byte_count(path) do |path|
      # much faster than wc https://gist.github.com/guilhermesimoes/d69e547884e556c3dc95
      File.foreach(path).reduce([0, 0]) {|counts, line| [counts[0]+1, counts[1]+line.length] }
    end
  end

  def file_summaries
    @files ||= absolute_path.glob('*fa').select do |f|
      File.file?(f)
    end.map do |f|
      lines, bytes = line_and_byte_count(f)
      Fasta.new(lines/2, bytes, f.basename('.*'), f.extname)
    end
  end

  def unaligned_fasta_sequence_counts
    @unaligned_fasta_sequence_counts ||= file_summaries.select(&:unaligned?).map(&:seqs)
  end

  # FIXME: this method should not exist. see above.
  def all_files_aligned?
    return false unless files.count > 1 # have to be at least 2 files to be aligned
    # for every fa file there is a corresponding afa file
    # means that chopping off the extensions there will be 2 of every file
    #
    # basename('') chops off both the prefix and the suffix provided so
    # /path/to/foo.fa => foo
    (absolute_path.glob('*.fa').map {|f| f.basename('.fa')} - absolute_path.glob('*.afa').map {|f| f.basename('.afa')}).empty?
  end

  def files_with_few_sequences
    # 3 sequences is 6 lines
    absolute_path.glob('*.fa').select {|f| f.each_line.count < 6  }
  end

  def files
    # both fa and afa files
    absolute_path.glob('*fa')
  end

  def unaligned_files
    absolute_path.glob('*.fa')
  end

  def aligned_files
    absolute_path.glob('*.afa')
  end

  def name
    absolute_path.basename.to_s.gsub('-', ' ')
  end

  def update_metrics!
    self.total_seqs = calculate_total_seqs
    self.total_bytes = calculate_total_bytes

    delete_empty_afa_files

    self.aligned = all_files_aligned?

    save
  end

  def delete_empty_afa_files
    absolute_path.glob('*.afa').each do |f|
      if f.size == 0
        $stderr.puts "deleted empty file: #{f.to_s}"
        f.unlink
      end
    end
  end

  def delete_files_with_few_sequences
    deleted_files = false

    files_with_few_sequences.each do |path|
      afapath = path.sub(/fa$/, 'afa')

      path.unlink
      $stderr.puts "deleted file with few sequences: #{path.to_s}"
      if afapath.file?
        afapath.unlink
        $stderr.puts "deleted file with few sequences: #{afapath.to_s}"
      end

      deleted_files = true
    end

    update_metrics! if deleted_files
  end

  def empty_afa_files
    absolute_path.glob('*.afa').select {|f| f.size == 0 }
  end

  # which file has the most sequences?
  def calculate_max_seqs
    file_summaries.map(&:seqs).max
  end

  # total number of sequences
  def calculate_total_seqs
    file_summaries.sum(&:seqs)
  end

  def calculate_total_bytes
    file_summaries.sum(&:bytes)
  end

  #FIXME: currently we need an occurrence for info
  # add to species table. also add file summary information for quick access. in
  # form
  # [{gene: "Species-COI", num_seqs: x, num_seqs_unaligned: y}]
  def gene_index
    file_summaries.group_by(&:prefix).map do |prefix, files|
      fa = files.find(&:unaligned?)
      afa = files.find(&:aligned?)

      {
        gene: prefix,
        num_seqs: fa&.seqs,
        num_seqs_aligned: afa&.seqs,
        retained: (fa && afa && fa.seqs > 0) ? afa.seqs/(fa.seqs.to_f) : nil
      }
    end
  end

  def self.genes_index_headers_tsv
    @genes_index_headers_tsv ||= %w(
      gene
      dir
      proportion_retained
      num_seqs_unaligned
      num_seqs_aligned
      kingdom
      phylum
      class
      order
      family
      genus
      species
      subspecies
      different_genbank_species
    ).join("\t") + "\n"
  end

  def genes_index_str
    @genes_index_str ||= gene_index.map do |gene|
      [
        gene[:gene],
        path,
        gene[:retained].to_s,
        gene[:num_seqs].to_s,
        gene[:num_seqs_aligned].to_s,
        taxon_kingdom,
        taxon_phylum,
        taxon_class,
        taxon_order,
        taxon_family,
        taxon_genus,
        taxon_species,
        taxon_subspecies,
        different_genbank_species
      ].join("\t")
    end.sort.join("\n")+"\n"
  end

  def genes_index_filesize(occurrence)
    genes_index_str(occurrence).length + self.class.genes_index_headers_tsv.length
  end

  #FIXME: if we have a Genes instead of Files table, this would be the place to move these
  # so you get all the Genes that need realigned, then you align_from_cache, then align otherwise
  #
  def self.files_needing_alignment
    Species.where(aligned: false).select(:path).to_a.map(&:unaligned_files).flatten.compact
  end

  def self.write_alignment_files_from_cache(fasta_files)
    return fasta_files unless Configuration.alignments_cache_path.present? && Configuration.alignments_cache_path.file?

    gdbm = GDBM.new(Configuration.alignments_cache_path.to_s, 0666, GDBM::READER)

    remaining = []

    fasta_files.each do |path|
      afapath = path.sub(/fa$/, 'afa')

      #TODO: refactor to AlignmentCache class

      # checksum of file is the key for the alignment
      key = Digest::SHA256.hexdigest(File.read(path))

      if gdbm.has_key?(key)
        File.write(afapath, gdbm[key])
      else
        remaining << path
      end
    end

    remaining
  ensure
    gdbm.close if gdbm
  end

  def self.align_file(path)
    afapath = path.sub(/fa$/, 'afa')

    tmpfile = ENV['TMPDIR'] ? File.join(ENV['TMPDIR'], path.basename.to_s) : Tempfile.new.path

    o,e,s = Open3.capture3("bin/mafft --adjustdirection --auto --inputorder --quiet #{path.to_s} > #{tmpfile}")
    raise "bin/mafft exited with status #{s} and output #{o} and error #{e}" unless s.success?
    o,e,s = Open3.capture3("bin/trimal -in #{tmpfile} -resoverlap 0.85 -seqoverlap 50 -gt 0.15")

    raise "bin/trimal exited with status #{s} and output #{o} and error #{e}" unless s.success?
    raise "empty alignment produced for #{t.source}" if o.blank?

    afapath.write o.split("\n").map { |l| l[0] == ">" ? "\n" + l.split.first : l }.join("").strip + "\n"
  rescue => e
    STDERR.puts "error when trying to align #{t.source}: #{e.message}"
  ensure
    File.unlink tmpfile
  end
end
