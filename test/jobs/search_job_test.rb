require 'test_helper'

class SearchJobTest < ActiveJob::TestCase
  test "job writes tarball" do
    Configuration.stubs(:app_version).returns('d609767')

    Dir.mktmpdir do |dir|
      #FIXME: programatically extend to capture all values
      swpoint = [29, -110]
      nepoint = [45, -73]

      #
      # FIXME: refactor to a separate model whose method accepts an IO object
      # to write the tar to and then we will test that (esp since we can test
      # using StringIO)
      #
      SearchJob.perform_now(dir, swpoint, nepoint, {})

      results = File.join(dir, 'phylogatr-results.tar.gz')

      assert File.file?(results), "ResultsWriter did not create results.tar"

      # unpack the tar
      `cd #{dir}; tar -xzf phylogatr-results.tar.gz`

      expected_results = File.join(fixture_path, 'expected_results')
      actual_results = File.join(dir, 'phylogatr-results')

      dirs = Dir.glob(File.join(dir, '*')).join("\n")

      assert File.directory?(actual_results), "expected phylogatr-results directory to be created after untarring results, instead these dirs exist:\n#{dirs}"

      # ignore the comparison of files that differ which will be addressed in the following test
      assert_equal "", `diff -rq #{expected_results} #{actual_results} | grep -v differ`.strip
      assert_equal "", `diff -r #{expected_results} #{actual_results}`.strip
    end
  end
end
