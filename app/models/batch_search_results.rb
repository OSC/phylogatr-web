class BatchSearchResults
  attr_reader :params
  def initialize(params)
    @params = (params || {}).symbolize_keys.select do |k,v|
      ([
      :southwest_corner_latitude,
      :southwest_corner_longitude,
      :northeast_corner_latitude,
      :northeast_corner_longitude,
      ].include?(k) || k.to_s.starts_with?("taxon_")) && v.present?
    end
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

  #FIXME torque specific
  def job_script
    <<~EOF
    #!/bin/bash
    #PBS -j oe
    #PBS -o #{stdout_path('$PBS_JOBID').to_s}

    set -xe
    module load ruby

    cd #{app_root.to_s}

    TARBALL=$TMPDIR/results.tar.gz
    ZIP=$TMPDIR/results.zip

    time bin/rails runner 'BatchSearchResults.new(#{params.inspect}).write_tar("'"${TARBALL}"'")' &
    tarpid=$!
    time bin/rails runner 'BatchSearchResults.new(#{params.inspect}).write_zip("'"${ZIP}"'")' &
    wait $!
    wait $tarpid

    mkdir -p #{output_path('$PBS_JOBID').to_s}

    cp $TARBALL #{tar_path('$PBS_JOBID').to_s}
    cp $ZIP #{zip_path('$PBS_JOBID').to_s}

    EOF
  end

  def app_root
    Rails.root
  end

  def results_root
    Pathname.new('/fs/scratch/PAS1604/results').join(cluster.id.to_s)
  end

  def stdout_path(jobid)
    results_root.join("#{jobid}.out")
  end

  def output_path(jobid)
    results_root.join(jobid)
  end

  def tar_path(jobid)
    output_path(jobid).join('phylogatr-results.tar.gz')
  end

  def zip_path(jobid)
    output_path(jobid).join('phylogatr-results.zip')
  end

  def write_tar(path)
    Pathname.new(path).tap { |d| d.dirname.mkpath }.open('wb') do |f|
      SearchResults.from_params(params).write_tar(f)
    end
  end

  def write_zip(path)
    Pathname.new(path).tap { |d| d.dirname.mkpath }.open('wb') do |f|
      SearchResults.from_params(params).write_zip(
        ZipTricks::BlockWrite.new { |chunk| f.write(chunk)  }
      )
    end
  end
end
