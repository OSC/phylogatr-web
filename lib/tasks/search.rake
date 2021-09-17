require 'benchmark'
require 'base64'

namespace :search do
  desc "search"
  task search: :environment do
    puts "searching to generate tarball"

    params = BatchSearchResults.deserialize_params(ENV['PARAMS'])

    raise 'PARAMS not set to base64 marshalled hash of params' unless params.present?

    Benchmark.bm do |x|
      x.report("metrics: ") {
        SearchResults.from_params(params).info.save(ENV['INFO_FILE'])
      }
      x.report("write pkg: ") {
        if params[:results_format] == 'zip'
          SearchResults.write_zip_to_file(params, ENV['RESULTS'], ENV['INFO_FILE'])
        else
          SearchResults.write_tar_to_file(params, ENV['RESULTS'], ENV['INFO_FILE'])
        end
      }
    end
  end


  desc "TODO"
  task perftest: :environment do
    # t = {
    #   taxon_kingdom: 'Animalia',
    #   taxon_phylum: 'Chordata',
    #   taxon_class: 'Reptilia',
    #   taxon_order: 'Squamata',
    #   taxon_family: 'Colubridae',
    #   taxon_genus: 'Pantherophis'
    # }



    def report(x, t)
      id = SecureRandom.uuid
      path = Rails.public_path.join('perftest', id)
      s = [-51.57433575655953, -176.83593750000003]
      n = [84.34391482566795, 158.55468750000003]
      c = Gene.in_bounds_with_taxonomy(s, n, t).count

      x.report("#{t.inspect} - #{c} - #{id}") {
        SearchJob.perform_now(path, s, n, t)
      }
    end

    Benchmark.bm do |x|
      report(x, {taxon_genus: 'Pantherophis'})
      report(x, {taxon_family: 'Colubridae'})
      report(x, {taxon_order: 'Squamata'})
      report(x, {taxon_class: 'Reptilia'})
      # report(x, {taxon_phylum: 'Chordata'}) #=> 17 minutes and counting...
      # report(x, {taxon_kingdom: 'Animalia'})
    end
  end
end
