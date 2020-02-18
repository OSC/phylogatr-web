class SearchJob < ActiveJob::Base
  queue_as :default

  def perform(swpoint, nepoint, taxonomy)
    Gene.joins("INNER JOIN occurrences ON occurrences.accession = genes.accession")
        .merge(Occurrence.in_bounds([swpoint, nepoint]).where(taxonomy))
        .order(:fasta_file_prefix, :accession)
        .distinct
        .find_each { |g|

          # write each accession to the specified file
          # TODO: will want to likely use the taxonomy from the occurrence
          # TODO: all the occurrences for a sequence should have the SAME taxonomy
          puts "#{g.fasta_file_prefix}: #{g.accession}"
    }
  end
end
