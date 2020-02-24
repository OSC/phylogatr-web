class Gene < ActiveRecord::Base
  def self.in_bounds_with_taxonomy(swpoint, nepoint, taxonomy)
    Gene.joins("INNER JOIN occurrences ON occurrences.accession = genes.accession")
        .merge(Occurrence.in_bounds([swpoint, nepoint]).where(taxonomy))
        .where.not(sequence_aligned: nil)
        .order(:fasta_file_prefix, :accession)
        .distinct
  end

  def self.find_each_in_bounds_with_taxonomy(swpoint, nepoint, taxonomy, batch_size: 1024)
    return to_enum(:find_each_in_bounds_with_taxonomy, swpoint, nepoint, taxonomy, batch_size: batch_size) unless block_given?

    #FIXME: below is problematic if the queries are happening while the database is
    # being modified
    count = self.in_bounds_with_taxonomy(swpoint, nepoint, taxonomy).count

    (0..count).step(batch_size) do |offset|
      self.in_bounds_with_taxonomy(swpoint, nepoint, taxonomy)
          .select('genes.*, occurrences.taxon_species') #FIXME: HACK
          .limit(batch_size)
          .offset(offset).each do |gene|
        yield gene
      end
    end

    # ids = self.in_bounds_with_taxonomy(swpoint, nepoint, taxonomy).pluck(:id)
    # ids.each_slice(batch_size) do |chunk|
    #   Gene.find(chunk, :order => "field(id, #{chunk.join(',')})").each do |gene|
    #     yield gene
    #   end
    # end
  end

  def to_fasta
    ">#{accession}\n#{sequence}"
  end

  def to_aligned_fasta
    ">#{accession}\n#{sequence_aligned}"
  end

end
