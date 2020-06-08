require 'shellwords'

class Species
  attr_reader :path

  def initialize(path)
    @path = path
  end

  Fasta = Struct.new(:seqs, :bytes)

  # FIXME: this method should not exist
  # rather, when generating and storing file data we should also store metadata in the database
  # and keep using the database as the access point for file information; files should only be on the file system
  # for accessing the file contents
  #
  def file_summaries
    @files ||= path.glob('*fa').map do |f|
      lines, bytes = `wc -lc #{Shellwords.escape(f.to_s)}`.strip.split.map(&:to_i)
      Fasta.new(lines/2, bytes)
    end
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
    path.basename.to_s.sub('-', ' ')
  end

  def self.update_occurrences(path)
    Species.new(Configuration.genbank_root.join(path)).update_occurrences
  end

  def update_occurrences
    Occurrence.where(taxon_species: name)
      .update_all("species_max_seqs_per_gene = '#{max_seqs}', species_total_seqs = '#{total_seqs}', species_total_bytes = '#{total_bytes}'")
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
end
