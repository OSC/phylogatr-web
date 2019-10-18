class SequencesController < ApplicationController

  # GET /sequences
  def index
    @sequences = Sequence.all
  end

  # GET /sequences/align
  def aligned
    # FIXME: should we store taxon id as a database column? the genbank source
    # feature has:
    # db_xref="taxon:94886"
    #
    # but this is not always taxon:... though for our records is it?
    # is taxon + gene what we are actually grouping together, or just species +
    # gene?
    # if we have a database of ALL possible species, could two different
    # taxonomy trees contain the same sjpecies+gene names but with different
    # parent taxons?
    #
    # if so we would need to do:
    #
    # bin/rails g migration AddTaxonidToSequence gb_taxon_id:integer
    #
    # start adding these as issues to GitLab - open questions about DESIGN

    # TODO:
    # group by species gene
    @sequences = Sequence.limit(5)

    render :index
  end

  # need to handle "species" and "subspecies" => merged into one group
  # so does a subspecies have a different taxonomic identifier
end
