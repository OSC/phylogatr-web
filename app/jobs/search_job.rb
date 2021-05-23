require 'rubygems/package'

class SearchJob < ApplicationJob
  queue_as :default

  # in_bounds_with_taxonomy.count # so we know the maximum
  def perform(path, swpoint, nepoint, taxonomy)
    tarball_path = Pathname.new(path).join("phylogatr-results.tar.gz")
    tarball_path.parent.mkpath

    tarball_path.open("wb") do |file|
      SearchResults.new(swpoint, nepoint, taxonomy).write_tar(file)
    end
  end
end
