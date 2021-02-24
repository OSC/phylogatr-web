namespace :app do
  desc "update json of valid taxonomies for taxon picker"
  task generate_taxon_json: :environment do
    # FIXME: Rails cache and controller to avoid manually doing
    # RAILS_ENV=production bin/rake app:generate_taxon_json > public/taxon.tsv.json
    taxons = Species.where(aligned: true).distinct.pluck(
          "taxon_kingdom",
          "taxon_phylum",
          "taxon_class",
          "taxon_order",
          "taxon_family",
          "taxon_genus",
          "taxon_species"
        )

    json = {
      data: taxons
    }.to_json

    puts json
  end

  desc "validate db"
  task validate_db: :environment do
    Species.fasta_grammar.verbose = true

    # validate all FASTA files
    species_with_invalid_fasta_files = Species.find_each.find_all(&:has_invalid_fasta_files?)

    if species_with_invalid_fasta_files.any?
      invalid_species_str = species_with_invalid_fasta_files.map {|s| "id: #{s.id} files: #{s.files.inspect}"}.join("\n")
      puts "species have invalid fasta files: #{invalid_species_str}\nall invalid species ids: #{species_with_invalid_fasta_files.map(&:id)}"
    else
      puts "validated"
    end
  end
end
