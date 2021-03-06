# frozen_string_literal: true

require 'yaml'

class PipelineMetrics
  class << self
    def gbif_filter_occurrences
      rf = ENV['PHYLOGATR_GBIF_RAW'] unless raise_if_no_file('PHYLOGATR_GBIF_RAW')
      ff = ENV['PHYLOGATR_GBIF_FILTERED'] unless raise_if_no_file('PHYLOGATR_GBIF_FILTERED')

      raw = `wc -l #{rf}`.split(' ')[0].to_i
      filtered = `wc -l #{ff}`.split(' ')[0].to_i

      PipelineMetrics.append_record(
      {
        'name'           => 'gbif_filter_occurrences',
        'input_records'  => raw,
        'output_records' => filtered
      })
    end

    def append_record(entry)
      entry['time'] = DateTime.now.to_s if entry['time'].nil?

      metrics = YAML.safe_load(File.read(metric_file)) || {}
      metrics['entries'] = metrics.fetch('entries', []).append(entry.to_h)

      File.open(metric_file, 'w+') { |f| f.write(metrics.to_yaml) }
    end

    def populate_database
      append_record({
        'name'          => 'populate_database',
        'input_records' => `wc -l #{ENV['WORKDIR']}/gbif.tsv`.split(' ')[0].to_i,
        'output_occurences'    => Occurrence.all.size,
        'output_species'       => Species.all.size,
      })
    end

    private

    def raise_if_no_file(env_var)
      val = ENV[env_var.to_s].to_s
      return false if val.present? && File.file?(val) && File.readable?(val)

      raise "ENV['#{env_var}']=#{ENV[env_var.to_s]} is not correct"
    end

    def metric_file
      @metric_file ||= begin
        raise 'environment variable PHYLOGATR_METRIC_FILE must be set' if ENV['PHYLOGATR_METRIC_FILE'].nil?

        f = ENV['PHYLOGATR_METRIC_FILE'].to_s
        FileUtils.touch(f)
        f
      end
    end
  end
end
