class BatchSearchResults
  attr_reader :params, :format, :search_results, :id

  # have the same interface as SearchResults
  delegate :to_s, :num_species, :estimated_tar_size, to: :search_results

  def self.id_from_param(param)
    param&.gsub('_', '.')
  end

  def self.to_param(id)
    id&.gsub('.', '_')
  end

  def to_param
    self.class.to_param(id)
  end

  def initialize(params)
    @id = self.class.id_from_param(params[:id]) if params[:id]
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
      bin: "/opt/torque/bin",
      submit_host: "owens.osc.edu"
    })
  end

  def info
    @info ||= cluster.job_adapter.info(id)
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

  def job_script_tgz
    <<~EOF
    #!/bin/bash
    #PBS -j oe
    #PBS -o #{stdout_path_template('$PBS_JOBID').to_s}

    umask 002

    set -xe
    module load ruby

    cd #{app_root.to_s}

    RESULTS=$TMPDIR/results.tar
    time RAILS_ENV=#{Rails.env} bin/rails runner 'SearchResults.write_tar_to_file(#{params.inspect}, "'"${RESULTS}"'")'

    mkdir -p #{output_path_template('$PBS_JOBID').to_s}

    cp $RESULTS #{tar_path_template('$PBS_JOBID').to_s}

    # FIXME: sleep for 30 seconds due to delay in writing to scratch and it
    # accessible from web app
    sleep 30

    EOF
  end

  def job_script_zip
    <<~EOF
    #!/bin/bash
    #PBS -j oe
    #PBS -o #{stdout_path_template('$PBS_JOBID').to_s}

    set -xe
    module load ruby

    cd #{app_root.to_s}

    RESULTS=$TMPDIR/results.zip
    time bin/rails runner 'SearchResults.write_zip_to_file(#{params.inspect}, "'"${RESULTS}"'")'

    mkdir -p #{output_path_template('$PBS_JOBID').to_s}

    cp $RESULTS #{zip_path_template('$PBS_JOBID').to_s}

    # FIXME: sleep for 10 seconds due to delay in writing to scratch and it
    # accessible from web app
    sleep 10

    EOF
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
