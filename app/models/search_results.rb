class SearchResults
  attr_reader :swpoint, :nepoint, :taxon

  def initialize(params)
    @swpoint = [params[:southwest_corner_latitude], params[:southwest_corner_longitude]]
    @nepoint = [params[:northeast_corner_latitude], params[:northeast_corner_longitude]]

    # taxon is a hash of:
    # taxon_kingdom: "Anamilia"
    # etc.
    # and is used for the query
    @taxon = params.select {|k,v| k.starts_with?("taxon_") && v.present? }.symbolize_keys
  end

  def occurrences
    @occurrences ||= Sequence.in_bounds([swpoint, nepoint]).where(taxon)
  end

  def sequences
    @sequences ||= occurrences.uniq {|o| o.accession }
  end

  def files
    sequences.group_by {|s| s.fasta_basename }
  end

  def species_count
    sequences.map(&:taxon_species).uniq.count
  end

  def genes_count
    files.size
  end
end
