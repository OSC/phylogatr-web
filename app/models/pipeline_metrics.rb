# frozen_string_literal: true

require 'yaml'

class PipelineMetrics
  class << self
    def gbif_filter_occurrences
      rf = ENV['PHYLOGATR_GBIF_RAW'] unless raise_if_no_file('PHYLOGATR_GBIF_RAW')
      ff = ENV['PHYLOGATR_GBIF_FILTERED'] unless raise_if_no_file('PHYLOGATR_GBIF_FILTERED')

      raw = `wc -l #{rf}`.split(' ')[0].to_i
      filtered = `wc -l #{ff}`.split(' ')[0].to_i

      FileUtils.touch(metric_file)
      metrics = YAML.safe_load(File.read(metric_file)) || {}
      metrics['entries'] = metrics.fetch('entries', []).concat [
        {
          'name'            => 'gbif_filter_occurrences',
          'time'  => DateTime.now.to_s,
          'input_records'   => raw,
          'output_records'  => filtered
        }
      ]

      File.open(metric_file, 'w+') { |f| f.write(metrics.to_yaml) }
    end

    private

    def raise_if_no_file(env_var)
      val = ENV[env_var.to_s].to_s
      return false if val.present? && File.file?(val) && File.readable?(val)

      raise "ENV['#{env_var}']=#{ENV[env_var.to_s]} is not correct"
    end

    def metric_file
      raise 'environment variable PHYLOGATR_METRIC_FILE must be set' if ENV['PHYLOGATR_METRIC_FILE'].nil?

      ENV['PHYLOGATR_METRIC_FILE'].to_s
    end
  end
end
