require 'csv'

records = []

puts Benchmark.measure {
  Occurrence.where(species_aligned: true).distinct.pluck(:taxon_class).each do |taxon_class|
    species = Occurrence.where(taxon_class: taxon_class).where(species_aligned: true).distinct.pluck(:species_path)
    seqs = species.map {|p| Species.new(Configuration.genbank_root.join(p)).unaligned_fasta_sequence_counts }.flatten
    stats = DescriptiveStatistics::Stats.new(seqs.sort)
    species_max = species.map {|p| Species.new(Configuration.genbank_root.join(p)) }.max { |a,b|
      a.unaligned_fasta_sequence_counts.sum <=> b.unaligned_fasta_sequence_counts.sum
    }
    records << [
      "taxon_class",
      taxon_class,
      species.count,
      stats.mean,
      stats.mode,
      stats.median,
      species_max.name,
      species_max.unaligned_fasta_sequence_counts.sum
    ]
  end
}



puts Benchmark.measure {
  Occurrence.where(species_aligned: true).distinct.pluck(:taxon_phylum).each do |taxon_phylum|
    species = Occurrence.where(taxon_phylum: taxon_phylum).where(species_aligned: true).distinct.pluck(:species_path)
    seqs = species.map {|p| Species.new(Configuration.genbank_root.join(p)).unaligned_fasta_sequence_counts }.flatten
    stats = DescriptiveStatistics::Stats.new(seqs.sort)
    species_max = species.map {|p| Species.new(Configuration.genbank_root.join(p)) }.max { |a,b|
      a.unaligned_fasta_sequence_counts.sum <=> b.unaligned_fasta_sequence_counts.sum
    }
    records << [
      "taxon_phylum",
      taxon_phylum,
      species.count,
      stats.mean,
      stats.mode,
      stats.median,
      species_max.name,
      species_max.unaligned_fasta_sequence_counts.sum
    ]
  end
}
puts Benchmark.measure {
  Occurrence.where(species_aligned: true).distinct.pluck(:taxon_kingdom).each do |taxon_kingdom|
    species = Occurrence.where(taxon_kingdom: taxon_kingdom).where(species_aligned: true).distinct.pluck(:species_path)
    seqs = species.map {|p| Species.new(Configuration.genbank_root.join(p)).unaligned_fasta_sequence_counts }.flatten
    stats = DescriptiveStatistics::Stats.new(seqs.sort)
    species_max = species.map {|p| Species.new(Configuration.genbank_root.join(p)) }.max { |a,b|
      a.unaligned_fasta_sequence_counts.sum <=> b.unaligned_fasta_sequence_counts.sum
    }
    records << [
      "taxon_kingdom",
      taxon_kingdom,
      species.count,
      stats.mean,
      stats.mode,
      stats.median,
      species_max.name,
      species_max.unaligned_fasta_sequence_counts.sum
    ]
  end
}

CSV.open("report.csv", "wb") do |csv|
  records.each do |record|
    csv << record
  end
end
