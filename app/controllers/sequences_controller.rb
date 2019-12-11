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
    @sequences = Sequence.alignable_groups(Sequence.all).values.flatten

    render :index
  end

  def new_search
  end

  # yes its more semantic to have a searches controller
  # but...
  #
  #
  # GET /search?lng=....&lat=...
  def search
    # TODO: split into POST search and GET search results (which can change to a
    # SearchesController) with new, create, show
    #
    params[:southwest_corner_latitude]
    params[:southwest_corner_longitude]

    params[:northeast_corner_latitude]
    params[:northeast_corner_longitude]

    # # what are the other params?
    # # should we use a form object? yes, for validations et al
    swpoint = [params[:southwest_corner_latitude], params[:southwest_corner_longitude]]
    nepoint = [params[:northeast_corner_latitude], params[:northeast_corner_longitude]]

    # # problem: what if the query is too big?
    # # validations would do a query + count to see...?
    @sequences = Sequence.in_bounds([swpoint, nepoint])

    flash.now[:notice] = "Found #{@sequences.count} results for swpoint: #{swpoint.inspect} and nepoint: #{nepoint.inspect}"
    render :index
  end
end
