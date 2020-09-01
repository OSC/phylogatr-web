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
      # 2. search_path(job_id, search: params)
      # 3. handle job submission error
      #
      # 4. note: I think that search => create... we would want to render a page "are you sure" here for the intermediate with the
      #
      # TODO: validate using form helper
      # TODO: id would come from  uuid or other job id, indicating where to find results

      id = BatchSearchResults.new(params).submit_job
      redirect_to search_path(id.gsub('.', '_'), search: params)

      # submit the job
      # then
      # 34492_quick-batch_ten_osc_edu

      # submit the job
      # build a runner bin/rails runner bin/code_to_be_run or lib/code_to_be_run.rb
      # or "Model.long_running_method"
    else
      #FIXME: default search could be instead of immediate,
      # to do in memory generation
      redirect_to search_path(0, search: params)
    end
  end

  # GET /searches/1234/?longitude=?&latitude=?&taxon_anima=?
  def show
    @id = params[:id]
    #TODO: right now the id is random and throwaway, the only thing
    # that matters here are the query params
    # this makes routing easy and would be the same routing if we
    # switch to background jobs; except background job would refer to
    # an id in this case

    respond_to do |format|
      format.tgz {
        if ::Configuration.batch_mode?
          send_file BatchSearchResults.new(params).tar_path(@id.gsub('_','.')), filename: "phylogatr_results.tar.gz"
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

          stream_tarball(response, params)
        end
      }
      format.zip {
        if ::Configuration.batch_mode?
          #FIXME or forget params and pass that through via a function to submit
          send_file BatchSearchResults.new(params).zip_path(@id.gsub('_','.')), filename: "phylogatr_results.zip"
        else
          response.headers["Content-Disposition"] = "attachment; filename=\"phylogatr_results.zip\""
          response.headers["Cache-Control"] = "no-cache"
          response.headers["Last-Modified"] = Time.now.httpdate.to_s
          response.headers["X-Accel-Buffering"] = "no"

          stream_zip(response, params)
        end
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
