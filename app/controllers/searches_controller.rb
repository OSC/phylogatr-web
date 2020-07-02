class SearchesController < ApplicationController
  include ActionController::Live

  # GET new
  def new
    # FIXME: add form helper? SearchForm (SearchResults becomes Search include ActiveModel)
    # https://thoughtbot.com/blog/activemodel-form-objects)
  end

  def taxon
  end

  # POST /searches
  def create
    # TODO: validate using form helper
    # TODO: id would come from  uuid or other job id, indicating where to find results
    redirect_to search_path(1234, search: params)
  end

  # GET /searches/1234/?longitude=?&latitude=?&taxon_anima=?
  def show
    #TODO: right now the id is random and throwaway, the only thing
    # that matters here are the query params
    # this makes routing easy and would be the same routing if we
    # switch to background jobs; except background job would refer to
    # an id in this case

    respond_to do |format|
      format.tgz {
        # see
        # https://piotrmurach.com/articles/streaming-large-zip-files-in-rails/
        # response.headers["Content-Disposition"] = ActionDispatch::Http::ContentDisposition.format(
        #   disposition: "attachment",
        #   filename: "phylogatr-results.tar.gz"
        # )
        response.headers["Content-Disposition"] = "attachment; filename=\"phylogatr_results.tar.gz\""
        #TODO: add back if we determine it ahead of time
        # response.delete_header("Content-Length")
        response.headers["Cache-Control"] = "no-cache"
        response.headers["Last-Modified"] = Time.now.httpdate.to_s
        response.headers["X-Accel-Buffering"] = "no"

        stream_tarball(response, params)
      }
      format.zip {
        response.headers["Content-Disposition"] = "attachment; filename=\"phylogatr_results.zip\""
        response.headers["Cache-Control"] = "no-cache"
        response.headers["Last-Modified"] = Time.now.httpdate.to_s
        response.headers["X-Accel-Buffering"] = "no"

        stream_zip(response, params)
      }
      format.html {
        @search_results = SearchResults.from_params(params[:search])
      }
    end
  end

  def stream_zip(response, params)
    SearchResults.from_params(params).write_zip(
      ZipTricks::BlockWrite.new { |chunk| response.stream.write(chunk)  }
    )
  ensure
    response.stream.close
  end

  def stream_tarball(response, params)
    SearchResults.from_params(params).write_tar(response.stream)
  ensure
    response.stream.close
  end
end
