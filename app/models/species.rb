require 'shellwords'

class Species
  attr_reader :path

  def initialize(path)
    @path = path
  end

  Fasta = Struct.new(:seqs, :bytes, :prefix, :extension) do
    def aligned?
      extension == ".afa"
    end
    def unaligned?
      ! aligned?
    end
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
    @files ||= path.glob('*fa').map do |f|
      lines, bytes = line_and_byte_count(f)
      Fasta.new(lines/2, bytes, f.basename('.*'), f.extname)
    end
  end

  def unaligned_fasta_sequence_counts
    @unaligned_fasta_sequence_counts ||= file_summaries.select(&:unaligned?).map(&:seqs)
  end

  # FIXME: this method should not exist. see above.
  def aligned?
    # for every fa file there is a corresponding afa file
    # means that chopping off the extensions there will be 2 of every file
    (path.glob('*.fa').map {|f| f.basename('.fa')} - path.glob('*.afa').map {|f| f.basename('.afa')}).empty?
  end

  def files
    # both fa and afa files
    path.glob('*fa')
  end

  def name
    path.basename.to_s.gsub('-', ' ')
  end

  def self.update_occurrences(path)
    Species.new(Configuration.genbank_root.join(path)).update_occurrences
  end

  def update_occurrences
    Occurrence.where(taxon_species: name)
      .update_all(species_max_seqs_per_gene: max_seqs, species_total_seqs: total_seqs, species_total_bytes: total_bytes, species_aligned: aligned?)
  end

  # which file has the most sequences?
  def max_seqs
    file_summaries.map(&:seqs).max
  end

  # total number of sequences
  def total_seqs
    file_summaries.sum(&:seqs)
  end

  def total_bytes
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

  def genes_index_str(occurrence)
    @genes_index_str ||= gene_index.map do |gene|
      [
        gene[:gene],
        Pathname.new(path).relative_path_from(Configuration.genbank_root),
        gene[:retained].to_s,
        gene[:num_seqs].to_s,
        gene[:num_seqs_aligned].to_s,
        occurrence.taxon_kingdom,
        occurrence.taxon_phylum,
        occurrence.taxon_class,
        occurrence.taxon_order,
        occurrence.taxon_family,
        occurrence.taxon_genus,
        occurrence.taxon_species,
        occurrence.taxon_subspecies,
        occurrence.different_genbank_species
      ].join("\t")
    end.join("\n")+"\n"
  end

  def genes_index_filesize(occurrence)
    genes_index_str(occurrence).length + self.class.genes_index_headers_tsv.length
  end
end
