namespace :pipeline do
  desc "filter out invalid or duplicate occurrences"
  task filter_occurrences: :environment do
    OccurrenceRecord.each_occurrence_slice_grouped_by_accession(STDIN) do |occurrences|
      OccurrenceRecord.filter(occurrences).each do |occurrence|
        puts occurrence.to_str
      end
    end
  end

  fasta_files = Rake::FileList[Configuration.genbank_root.join('**/*\.fa')]

  desc "delete all fasta alignment files"
  multitask :clobber_alignments do
    rm_f fasta_files.ext('.afa')
  end

  desc "align fasta files"
  multitask :align => fasta_files.ext('.afa')

  desc "alignments needed"
  task :alignments_needed do
    puts fasta_files.ext('.afa').to_a.reject {|f| File.file?(f) }
  end

  desc "alignment stats"
  task "stats" do
    num_aligned = fasta_files.ext('.afa').to_a.select {|f| File.file?(f) }.count
    puts "#{num_aligned} aligned files (.afa)"
    puts "#{fasta_files.count - num_aligned} need aligned"
  end

  desc "rm empty alignments"
  multitask :rm_empty_alignments do
    rm_f fasta_files.ext('.afa').to_a.select {|f| File.file?(f) && File::Stat.new(f).size < 10 }
  end

  desc "empty alignments"
  task :emtpy_alignments do
    puts fasta_files.ext('.afa').to_a.select {|f| File.file?(f) && File::Stat.new(f).size < 10 }
  end

  rule '.afa' => '.fa' do |t|
    # https://avdi.codes/rake-part-3-rules/
    # source path is .fa: t.source
    # dest path is afa: t.name
    tmpfile = ENV['TMPDIR'] ? File.join(ENV['TMPDIR'], File.basename(t.source)) : Tempfile.new.path

    # TODO: if cache is used pull from cache
    # i.e.
    # if CACHE check cache first and use that

    o,e,s = Open3.capture3("bin/mafft --adjustdirection --auto --inputorder --quiet #{t.source} > #{tmpfile}")
    raise "bin/mafft exited with status #{s} and output #{o} and error #{e}" unless s.success?
    o,e,s = Open3.capture3("bin/trimal -in #{tmpfile} -resoverlap 0.85 -seqoverlap 50 -gt 0.15")
    raise "bin/trimal exited with status #{s} and output #{o} and error #{e}" unless s.success?
    raise "empty alignment produced for #{t.source}" if o.blank?

    # get rid of newlines not at end of sequence header
    # get rid of all info from sequence header not >ACCESSION
    File.write t.name, o.split("\n").map { |l| l[0] == ">" ? "\n" + l.split.first : l }.join("").strip + "\n"

    File.unlink tmpfile
  rescue => e
    STDERR.puts "error when trying to align #{t.source}: #{e.message}"
    File.unlink tmpfile
  end

  #TODO: task update cache on fasta_files is separate, its okay if it takes some time - it has to be sequential!
end
