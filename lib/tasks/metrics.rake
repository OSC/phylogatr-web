namespace :metrics do
  desc "print species metrics"
  task species: :environment do
    files = Species.where(aligned: true).to_a.map do |s|
      s.file_summaries.select(&:aligned?)
    end

    puts "number of species: #{files.count}"
    puts "number of alignments: #{files.flatten.count}"
    puts "avg number of alignments per species: #{files.map(&:count).sum.to_f / files.count}"
    puts "avg number of sequences per alignment: #{files.flatten.map(&:seqs).sum.to_f / files.count}"

    genes = Species.joins(:occurrences).where(aligned: true).select('occurrences.genes').to_a.map(&:genes).uniq
    genes = genes.map(&:split).flatten.sort.uniq
    puts "number of genes: #{genes.count}"

    puts "\nspecies count per kingdom:"
    Species.where(aligned: true).group(:taxon_kingdom).count.to_a.sort_by {|t| -t.last }.each do |pair|
      puts "%-16s %s" % pair
    end

    puts "\nspecies count per phylum:"
    Species.where(aligned: true).group(:taxon_phylum).count.to_a.sort_by {|t| -t.last }.each do |pair|
      puts "%-16s %s" % pair
    end
  end

  task :filtered_bold, [:directory] => :environment do |_task, args|
    data_path = args[:directory]
    raise "#{data_path} is not a valid directory" unless File.directory?(data_path)

    total_records = 0
    invalid_records = 0
    tmp_file = '/tmp/bold.tsv'

    Dir.glob("#{data_path}/*.tsv").each do |f|
      sh "tail -n +1 #{f} | cut -d'\t' -f1,3,4,5,10,12,14,16,20,22,24,47,48,70,71,72 > #{tmp_file}"

      CSV.foreach(tmp_file, col_sep: "\t", headers: BoldRecord::HEADERS) do |record|
        total_records += 1
        invalid_records += 1 if BoldRecord.new(record.to_h).invalid?
      end
    end

    puts "#{format('%.2f', (invalid_records / total_records.to_f) * 100)}% of records were found to be invalid."
    puts "total records: #{total_records}"
    puts "invalid records: #{invalid_records}"
  end

  desc 'Gbif records with no latitude or longitude'
  task :gbif_no_location, [:occurrences_txt] => :environment do |_task, args|
    files = Dir.glob("#{args[:occurrences_txt]}*")

    results = Parallel.map(files) do |file|
      res = { total: 0, invalid: 0 }

      CSV.foreach(file, col_sep: "\t", headers: true, liberal_parsing: true) do |record|
        res[:total] += 1
        res[:invalid] += 1 if record['decimalLatitude'].nil? || record['decimalLongitude'].nil?
      end

      res
    end.each_with_object({}) do |tmp, total|
      total[:total] = 0 if total[:total].nil?
      total[:invalid] = 0 if total[:invalid].nil?

      total[:total] += tmp[:total].to_i
      total[:invalid] += tmp[:invalid].to_i
    end

    puts "#{format('%.2f', (results[:invalid] / results[:total].to_f) * 100)}% of records were found to have no lat & lon coordinates."
    puts "total records: #{results[:total]}"
    puts "invalid records: #{results[:invalid]}"
  end

  task gbif_filter_occurrences: :environment do
    PipelineMetrics.gbif_filter_occurrences
  end

  task :save_record do
    raise 'requried environment variables RECORD_NAME' unless ENV['RECORD_NAME']

    record = {
      'name' => ENV['RECORD_NAME'].to_s,
    }.tap do |hsh|
      ENV.select do |k, v|
        /^INPUT_[\w_]+|^OUTPUT_[\w_]+/.match?(k)
      end.each do |k, v|
        hsh[k.downcase.to_s] = v
      end
    end

    PipelineMetrics.append_record(record)
  end

  task populate_database: :environment do
    PipelineMetrics.populate_database
  end
end
