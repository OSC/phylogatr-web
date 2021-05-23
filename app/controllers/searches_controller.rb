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
    # FIXME: instead of a mode, could be a query param i.e. mode=batch
    if ::Configuration.batch_mode?
      # for the mode to submit the job we would:
      #
      # 1. submit job
      # 2. search_path(job_id, search: search_params)
      # 3. handle job submission error
      #
      # 4. note: I think that search => create... we would want to render a page "are you sure" here for the intermediate with the
      #
      # TODO: validate using form helper
      #
      search = BatchSearchResults.new(search_params)
      search.submit_job
      redirect_to search_path(search.to_param, search.params)
    else
      # immediate
      redirect_to search_path(0, SearchResults.clean_params(search_params))
    end
  end

  # GET /searches/1234/?longitude=?&latitude=?&taxon_anima=?
  def show
    @id = search_params[:id]
    if ::Configuration.batch_mode?
      @search_results = BatchSearchResults.new(search_params)
    else
      @search_results = SearchResults.from_params(search_params)
    end

    #TODO: right now the id is random and throwaway, the only thing
    # that matters here are the query search_params
    # this makes routing easy and would be the same routing if we
    # switch to background jobs; except background job would refer to
    # an id in this case

    respond_to do |format|
      format.tgz {
        if ::Configuration.batch_mode?
          send_file @search_results.tar_path, filename: "phylogatr_results.tar.gz"
        else
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

          stream_tarball(response)
        end
      }
      format.zip {
        if ::Configuration.batch_mode?
          send_file BatchSearchResults.new(search_params).zip_path, filename: "phylogatr_results.zip"
        else
          response.headers["Content-Disposition"] = "attachment; filename=\"phylogatr_results.zip\""
          response.headers["Cache-Control"] = "no-cache"
          response.headers["Last-Modified"] = Time.now.httpdate.to_s
          response.headers["X-Accel-Buffering"] = "no"

          stream_zip(response)
        end
      }
      format.html {
        if ::Configuration.batch_mode?
          render :show_batch
        end
      }
      format.js {
        if ::Configuration.batch_mode?
          render :show_batch
        end
      }
    end
  end

  def stream_zip(response)
    @search_results.write_zip(
      ZipTricks::BlockWrite.new { |chunk| response.stream.write(chunk)  }
    )
  ensure
    response.stream.close
  end

  def stream_tarball(response)
    @search_results.write_tar(response.stream)
  ensure
    response.stream.close
  end


  private

  def search_params
    params.permit!
    params.to_h
  end
end
