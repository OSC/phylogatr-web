ENV['RAILS_ENV'] ||= 'test'
ENV['GENBANK_ROOT'] ||= File.expand_path('../../test/data/reptilia_genes', __FILE__)
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'mocha/minitest'

Minitest::Test.make_my_diffs_pretty!

class ActiveSupport::TestCase
  # TODO:
  # if ENV['RAILS_ENV'] == 'test'
  #   Rails.application.load_seed if Occurrence.count == 0
  # end

  def mock_data(path)
    Rails.root.join('test', 'data', path)
  end

  def compare_file_sorted(a, b)
    # copy impl of FileUtils.copmare_file with addition of sorting
    return false unless File.size(a) == File.size(b)
    File.open(a, 'rb') {|fa|
      File.open(b, 'rb') {|fb|
        return fa.readlines.sort.join("\n") == fb.readlines.sort.join("\n")
      }
    }
  end

  def assert_files_same(a, b)
    a = a.to_s
    b = b.to_s
    assert FileUtils.compare_file(a, b), (compare_file_sorted(a, b) ? "#{a} and #{b} sort order differs" : "#{a} and #{b} content differs")
  end
end
