ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'socket'
if Socket.gethostname.start_with?("webtest")
  ENV['BUNDLE_PATH'] = "vendor/bundle"
  ENV['BUNDLE_DISABLE_SHARED_GEMS'] = "true"
end

require 'bundler/setup' # Set up gems listed in the Gemfile.

# load dotenv files before "before_configuration" callback
require File.expand_path('../configuration_singleton', __FILE__)

# global instance to access and use
Configuration = ConfigurationSingleton.new
Configuration.load_dotenv_files

# set defaults to address OodAppkit.dataroot issue
ENV['OOD_DATAROOT'] = Configuration.dataroot.to_s
