require 'base64'

class BatchSearchResults
  attr_reader :params, :format, :search_results, :id

  # have the same interface as SearchResults
  delegate :num_species, :estimated_tar_size, :percent_complete, :message, to: :info
  delegate :to_s, to: :search_results

  def serialize_params
    Serialize.to_str(params)
  end

  def self.deserialize_params(str)
    Serialize.from_str(str)
  end

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
    # preferable cause we can utilize env vars like $SLURM_JOBID
    #
    @id = cluster.job_adapter.submit(OodCore::Job::Script.new(
      content: self.send("job_script_#{format}"),

      # FIXME: params as part of job name?
      accounting_id: "PAS1604",
      job_name: "phylogatr_search",
      wall_time: 3600,
      # native: [ "--partition", "quick", "--nodes", "1", "--ntasks-per-node", "1"  ]
      native: [ "--nodes", "1", "--ntasks-per-node", "2"  ]
    ))
  end

  def cluster
    @cluster ||= OodCore::Cluster.new(id: 'owens-quick', job: {
      adapter: "slurm",
      cluster: "owens",
      host: "owens-slurm01.ten.osc.edu",
      lib: "/usr/lib64",
      bin: "/usr/bin",
      conf: "/etc/slurm/slurm.conf",
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

  def create_info(path = nil)
    if path
      search_results.info.save(path)
    else
      search_results.info.save(json_path_template(id))
    end
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
    #SBATCH --output=#{stdout_path_template('%j').to_s}

    umask 002

    set -xe
    module load ruby

    mkdir -p #{output_path_template('$SLURM_JOBID').to_s}

    # cd #{app_root.to_s}

    # batch job to use tar.gz of the genbank_root directory in root of the app directory
    cp #{Configuration.genes_tarball_path.to_s} $TMPDIR
    ( cd $TMPDIR; tar xzf #{Configuration.genes_tarball_path.basename.to_s} )

    export GENBANK_ROOT=$TMPDIR/genes
    export RAILS_ENV=#{Rails.env}
    export INFO_FILE=#{json_path_template('$SLURM_JOBID')}
    export RESULTS=$TMPDIR/results.#{pkg}
    export PARAMS=#{serialize_params}
    export DATABASE_URL=#{ENV['REAL_DATABASE_URL']}

    # execute command
    singularity exec #{Configuration.sif_path} /app/bin/bundle exec /app/bin/db search

    # cp results to file
    cp $RESULTS #{package_path_template(pkg, '$SLURM_JOBID').to_s}

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
