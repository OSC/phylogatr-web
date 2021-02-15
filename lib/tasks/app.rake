namespace :app do
  desc "update json of valid taxonomies for taxon picker"
  task generate_taxon_json: :environment do
    # FIXME: Rails cache and controller
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
end
