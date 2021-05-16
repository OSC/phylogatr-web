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
  end
end
