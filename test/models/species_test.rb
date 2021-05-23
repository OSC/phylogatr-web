require 'test_helper'
require 'fileutils'

class SpeciesTest < ActiveJob::TestCase
  test "needs_aligned" do
    Dir.mktmpdir do |dir|
      # copy genes to dir
      FileUtils.cp_r Configuration.genbank_root.to_s, dir

      Configuration.stubs(:genbank_root).returns(Pathname.new(dir))

      # delete alignment files of first 3
      species = Species.first(3)
      files = species.map {|s| s.files.to_a.select {|f| f.extname == 'afa' }}.flatten
      puts files
      files.each(&:unlink)

      # update metrics
      species.map(&:update_metrics!)

      # verify
      assert_equal files.map {|f| f.relative_path_from(Configuration.genbank_root)}, Species.files_needing_alignment

      # undo changes
      Configuration.unstub(:genbank_root)
      species.each(&:update_metrics!)
    end
  end
end
