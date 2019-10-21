require "open3"
require "stringio"

class Sequence < ActiveRecord::Base
  acts_as_mappable

  # return array of array's of sequences, grouped by sequences that have shared gene name
  #
  # FIXME: this doesn't work because I end up doing all of the
  def self.alignable_groups(threshold: 3)
    Sequence.all.to_a.group_by {|s| "#{s.taxon_genbank_species} - #{s.gene_name}" }.select {|k, g| g.count > threshold }
  end

  def self.align_sequences(threshold: 3)
    groups = Sequence.alignable_groups(threshold: 3)

    aligned = []

    groups.values.each do |sequences|
      fasta_file = sequences.sort_by { |s| s.accession  }.map(&:to_fasta).join("\n")

      stdout_str, stderr_str, status = Open3.capture3("./bin/muscle3.8.31_i86linux64", stdin_data: fasta_file)
      if(status.success?)
        #
        # stdout_str is the FASTA file
        # it is interweaved and out of order, but
        # order doesn't matter
        # and the BioPython/Ruby can handle formatting as non-interweaved format
        #
        ff = Bio::FlatFile.new(Bio::FastaFormat, StringIO.new(stdout_str))
        ff.each_entry do |f|
          # iterating through aligned sequences, lets update them
          sequence = sequences.find {|s| s.accession == f.accession && s.gene_name == f.locus }

          # FIXME: handle nil edgecase
          sequence.sequence_aligned = f.seq
          sequence.save
        end
      else
      end
    end
  end

  # FIXME: may be inaccurrate, but putting gene_name right oafter accession
  # enables easy parsing of Gene name from Bio::FlatFile#locus
  def to_fasta
    ">gb|#{accession}|#{gene_name}| #{taxon_genbank_species}\n#{sequence}"
  end

  def to_aligned_fasta
    ">gb#{accession}|#{gene_name}| #{taxon_genbank_species}\n#{sequence_aligned}"
  end
end

