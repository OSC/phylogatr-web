class BatchSearchResults
  attr_reader :params, :format, :search_results, :id

  # have the same interface as SearchResults
  delegate :num_species, :estimated_tar_size, :percent_complete, :message, to: :info
  delegate :to_s, to: :search_results

  def self.id_from_param(param)
    param&.gsub('_', '.')
  end

  def self.to_param(id)
    id&.gsub('.', '_')
  end

  def to_param
    self.class.to_param(id)
  end

  def initialize(params, id=nil)
    if id
      @id = id
    else
      @id = self.class.id_from_param(params[:id]) if params[:id]
    end
    @format = ["tgz", "zip"].include?(params["results_format"]) ? params["results_format"] : "tgz"
    @params = SearchResults.clean_params(params)
    @search_results = SearchResults.from_params(@params)
  end

  # ################################################
  # use Script to submit most args
  #
  # add #!bin/bash shebang to content
  # need to have nodes/cpu count
  # should have added that a long very long time ago
  # ################################################
  def submit_job
    # generate headers and insert into batch script INSTEAD OF command line args
    # skip #!/bin/bash and then do that
    # preferable cause we can utilize env vars like $PBS_JOBID
    #
    @id = cluster.job_adapter.submit(OodCore::Job::Script.new(
      content: self.send("job_script_#{format}"),
      job_name: "phylogatr_search",
      wall_time: 3600,
      native: ['-l', 'nodes=1:ppn=1:owens']
    ))
  end

  def cluster
    @cluster ||= OodCore::Cluster.new(id: 'quick', job: {
      adapter: "torque",
      host: "quick-batch.ten.osc.edu",
      lib: "/opt/torque/lib64",
      bin: "/opt/torque/bin"
    })
  end

  def job_info
    @job_info ||= cluster.job_adapter.info(id)
  end

  # batch info returns from a file
  def info
    return @info if @info

    json_path_template(id).parent.open {
      p = json_path_template(id)
      @info ||= (p.file? ? SearchResultsInfo.load(p) : SearchResultsInfo.new)
    }
  rescue
    @info = SearchResultsInfo.new
  end

  def create_info
    search_results.info.save(json_path_template(id))
  end

  def tar?
    output_path_template(id).open { tar_path.file? }
  rescue
    false
  end

  def zip?
    output_path_template(id).open { zip_path.file? }
  rescue
    false
  end

  def tar_path
    tar_path_template(id)
  end

  def zip_path
    zip_path_template(id)
  end

  def stdout_path
    stdout_path_template(id)
  end

  def job_script(pkg)
    <<~EOF
    #!/bin/bash
    #PBS -j oe
    #PBS -o #{stdout_path_template('$PBS_JOBID').to_s}

    umask 002

    set -xe
    module load ruby

    mkdir -p #{output_path_template('$PBS_JOBID').to_s}

    cd #{app_root.to_s}

    # genbank_root will have a genes_aligned.tar.gz besides it that is the tar of that dir
    cp #{Configuration.genbank_root.parent.join('genes_aligned.tar.gz')} $TMPDIR/genes_aligned.tar.gz
    cd $TMPDIR
    tar xzf genes_aligned.tar.gz
    cd $PBS_O_WORKDIR
    export GENBANK_ROOT=$TMPDIR/genes

    time RAILS_ENV=#{Rails.env} bin/rails runner 'BatchSearchResults.new(#{params.inspect}, "'"${PBS_JOBID}"'").create_info'

    INFO_FILE=#{json_path_template('$PBS_JOBID')}

    RESULTS=$TMPDIR/results.tar
    time RAILS_ENV=#{Rails.env} bin/rails runner 'SearchResults.write_#{pkg}_to_file(#{params.inspect}, "'"${RESULTS}"'", "'"${INFO_FILE}"'")'

    cp $RESULTS #{package_path_template(pkg, '$PBS_JOBID').to_s}

    # sleep for 30 seconds due to delay in writing to scratch and it accessible from web app
    sleep 30

    EOF
  end

  def package_path_template(pkg, jobid)
    if pkg == 'zip'
      zip_path_template(jobid)
    else
      tar_path_template(jobid)
    end
  end

  def job_script_tgz
    job_script('tar')
  end

  def job_script_zip
    job_script('zip')
  end

  def app_root
    Rails.root
  end

  def results_root
    Pathname.new('/fs/scratch/PAS1604/results').join(cluster.id.to_s)
  end

  def stdout_path_template(jobid)
    results_root.join("#{jobid}.out")
  end

  def json_path_template(jobid)
    results_root.join("#{jobid}.json")
  end

  def output_path_template(jobid)
    results_root.join(jobid)
  end

  def tar_path_template(jobid)
    output_path_template(jobid).join('phylogatr-results.tar.gz')
  end

  def zip_path_template(jobid)
    output_path_template(jobid).join('phylogatr-results.zip')
  end
end
