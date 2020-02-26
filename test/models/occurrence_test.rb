require 'test_helper'

class GeneTest < ActiveJob::TestCase
  test "occurrence scope filters on taxonomy" do
    swpoint = [29, -110]
    nepoint = [45, -73]
    taxonomy = {
      taxon_kingdom: 'Animalia',
      taxon_phylum: 'Chordata',
      taxon_class: 'Reptilia',
      taxon_order: 'Squamata',
      taxon_family: 'Colubridae',
      taxon_genus: 'Pantherophis',
      taxon_species: 'Pantherophis vulpinus'
    }

    assert_equal 1, Occurrence.in_bounds_with_taxonomy_joins_genes(swpoint, nepoint, taxonomy).count
  end
end
