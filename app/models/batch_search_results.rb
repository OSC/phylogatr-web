class BatchSearchResults
  attr_reader :params
  def initialize(params, jobid: nil)
    @params = params
    @jobid = jobid
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
    cluster.job_adapter.submit(OodCore::Job::Script.new(
      content: job_script,
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

  def job_script
    <<~FOO
    #!/bin/bash
    #PBS -j oe
    #PBS -o #{stdout_path.to_s}
    module load ruby

    #FIXME: in Slurm? or do PBS_O_WORKDIR?
    cd #{Rails.root.to_s}

    # FIXME: write_tar or write_zip? need to know ahead of time (preview?)
    time bin/rails runner 'BatchSearchResults.new(#{params.inspect}).write_tar'
    FOO
  end


  def results_root
    Pathname.new('/fs/scratch/PAS1604/results').join(cluster.id.to_s)
  end

  def output_path
    results_root.join(jobid, 'phylogatr-results')
  end

  def stdout_path
    results_root.join('$PBS_JOBID.out')
  end

  def jobid
    id = @jobid || ENV['PBS_JOBID'] || ENV['SLURM_JOBID']
    raise "Job id not specified" unless id
    id
  end

  def tar_path
    output_path.sub_ext('.tar.gz')
  end

  def zip_path
    output_path.sub_ext('.zip')
  end

  def write_tar
    tar_path.dirname.mkpath
    tar_path.open('wb') do |f|
      SearchResults.from_params(params).write_tar(f)
    end
    # TODO: rescue exception saved
  end

  def write_zip
    zip_path.dirname.mkpath
    zip_path.open('wb') do |f|
      SearchResults.from_params(params).write_zip(
        ZipTricks::BlockWrite.new { |chunk| f.write(chunk)  }
      )
    end
  end
end
