require 'test_helper'

class SearchJobTest < ActiveJob::TestCase
  test "job writes tarball" do
    Dir.mktmpdir do |dir|
      #FIXME: programatically extend to capture all values
      swpoint = [29, -110]
      nepoint = [45, -73]

      dir = "/users/PZS0562/efranz/ondemand/dev/phylogatr/tmp"
      SearchJob.perform_now(dir, swpoint, nepoint, {})

      results = File.join(dir, 'results.tar')

      assert File.file?(results), "ResultsWriter did not create results.tar"
      assert_equal "seqs/Pantherophis-obsoletus-COI.fa\nseqs/Pantherophis-vulpinus-C-MOS.fa\n", `tar -tf #{results}`
      assert_equal ">DQ902089\ntctcctgcatctcctcggct", `tar -xOf #{results} seqs/Pantherophis-vulpinus-C-MOS.fa`.strip
    end
  end
end
