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
end
