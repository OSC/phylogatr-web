require 'test_helper'

class BoldRecordTest < ActiveSupport::TestCase
  #FIXME: there is fixture_file('') so maybe
  # the fixtures dir is still the correct place?
  #

  test "taxonomy for home bold page" do
    uri = 'file://' + mock_data('bold_taxonomy/home.html').to_s
    taxons = [
      %w(Acanthocephala 2306 /index.php/Taxbrowser_Taxonpage?taxid=11 phylum),
      %w(Acoelomorpha 20 /index.php/Taxbrowser_Taxonpage?taxid=296140 phylum),
      %w(Annelida 102966 /index.php/Taxbrowser_Taxonpage?taxid=2 phylum),
      %w(Arthropoda 10058285 /index.php/Taxbrowser_Taxonpage?taxid=20 phylum),
      %w(Brachiopoda 310 /index.php/Taxbrowser_Taxonpage?taxid=9 phylum),
      %w(Bryozoa 4133 /index.php/Taxbrowser_Taxonpage?taxid=7 phylum),
      %w(Chaetognatha 1743 /index.php/Taxbrowser_Taxonpage?taxid=13 phylum),
      %w(Chordata 839204 /index.php/Taxbrowser_Taxonpage?taxid=18 phylum),
      %w(Cnidaria 29865 /index.php/Taxbrowser_Taxonpage?taxid=3 phylum),
      %w(Ctenophora 511 /index.php/Taxbrowser_Taxonpage?taxid=249225 phylum),
      %w(Cycliophora 326 /index.php/Taxbrowser_Taxonpage?taxid=79455 phylum),
      %w(Echinodermata 57293 /index.php/Taxbrowser_Taxonpage?taxid=4 phylum),
      %w(Entoprocta 65 /index.php/Taxbrowser_Taxonpage?taxid=299518 phylum),
      %w(Gastrotricha 1351 /index.php/Taxbrowser_Taxonpage?taxid=392665 phylum),
      %w(Gnathostomulida 24 /index.php/Taxbrowser_Taxonpage?taxid=78956 phylum),
      %w(Hemichordata 234 /index.php/Taxbrowser_Taxonpage?taxid=21 phylum),
      %w(Kinorhyncha 720 /index.php/Taxbrowser_Taxonpage?taxid=392666 phylum),
      %w(Mollusca 243013 /index.php/Taxbrowser_Taxonpage?taxid=23 phylum),
      %w(Nematoda 34770 /index.php/Taxbrowser_Taxonpage?taxid=19 phylum),
      %w(Nematomorpha 401 /index.php/Taxbrowser_Taxonpage?taxid=261851 phylum),
      %w(Nemertea 5669 /index.php/Taxbrowser_Taxonpage?taxid=497163 phylum),
      %w(Onychophora 1393 /index.php/Taxbrowser_Taxonpage?taxid=10 phylum),
      %w(Phoronida 160 /index.php/Taxbrowser_Taxonpage?taxid=370374 phylum),
      %w(Placozoa 20 /index.php/Taxbrowser_Taxonpage?taxid=321215 phylum),
      %w(Platyhelminthes 38589 /index.php/Taxbrowser_Taxonpage?taxid=5 phylum),
      %w(Porifera 7808 /index.php/Taxbrowser_Taxonpage?taxid=24818 phylum),
      %w(Priapulida 148 /index.php/Taxbrowser_Taxonpage?taxid=392644 phylum),
      %w(Rhombozoa 48 /index.php/Taxbrowser_Taxonpage?taxid=531453 phylum),
      %w(Rotifera 12761 /index.php/Taxbrowser_Taxonpage?taxid=16 phylum),
      %w(Sipuncula 1318 /index.php/Taxbrowser_Taxonpage?taxid=15 phylum),
      %w(Tardigrada 2908 /index.php/Taxbrowser_Taxonpage?taxid=26033 phylum),
      %w(Xenacoelomorpha 18 /index.php/Taxbrowser_Taxonpage?taxid=531452 phylum),
      %w(Bryophyta 21899 /index.php/Taxbrowser_Taxonpage?taxid=176192 phylum),
      %w(Chlorophyta 14519 /index.php/Taxbrowser_Taxonpage?taxid=112296 phylum),
      %w(Lycopodiophyta 1215 /index.php/Taxbrowser_Taxonpage?taxid=38696 phylum),
      %w(Magnoliophyta 366736 /index.php/Taxbrowser_Taxonpage?taxid=12 phylum),
      %w(Pinophyta 7068 /index.php/Taxbrowser_Taxonpage?taxid=251587 phylum),
      %w(Pteridophyta 11393 /index.php/Taxbrowser_Taxonpage?taxid=38074 phylum),
      %w(Rhodophyta 54630 /index.php/Taxbrowser_Taxonpage?taxid=48327 phylum),
      %w(Ascomycota 98397 /index.php/Taxbrowser_Taxonpage?taxid=34 phylum),
      %w(Basidiomycota 66488 /index.php/Taxbrowser_Taxonpage?taxid=23675 phylum),
      %w(Chytridiomycota 293 /index.php/Taxbrowser_Taxonpage?taxid=23691 phylum),
      %w(Glomeromycota 3529 /index.php/Taxbrowser_Taxonpage?taxid=85867 phylum),
      %w(Myxomycota 235 /index.php/Taxbrowser_Taxonpage?taxid=83947 phylum),
      %w(Zygomycota 3273 /index.php/Taxbrowser_Taxonpage?taxid=23738 phylum),
      %w(Chlorarachniophyta 67 /index.php/Taxbrowser_Taxonpage?taxid=316986 phylum),
      %w(Ciliophora 788 /index.php/Taxbrowser_Taxonpage?taxid=72834 phylum),
      %w(Heterokontophyta 7209 /index.php/Taxbrowser_Taxonpage?taxid=53944 phylum),
      %w(Pyrrophycophyta 2337 /index.php/Taxbrowser_Taxonpage?taxid=317010 phylum)
    ].map {|t| BoldRecord::Taxonomy.new(t[0], t[1], 'https://www.boldsystems.org' + t[2], t[3]) }

    assert_equal taxons, BoldRecord.taxonomy(uri)
  end

  test "taxonomy for arthropoda bold page" do
    uri = 'file://' + mock_data('bold_taxonomy/arthropoda.html').to_s
    taxons = [
      %w(Acrothoracica 4 /index.php/Taxbrowser_Taxonpage?taxid=987854 class),
      %w(Arachnida 460142 /index.php/Taxbrowser_Taxonpage?taxid=63 class),
      %w(Branchiopoda 19994 /index.php/Taxbrowser_Taxonpage?taxid=68 class),
      %w(Cephalocarida 27 /index.php/Taxbrowser_Taxonpage?taxid=73 class),
      %w(Chilopoda 4662 /index.php/Taxbrowser_Taxonpage?taxid=75 class),
      %w(Collembola 193826 /index.php/Taxbrowser_Taxonpage?taxid=372 class),
      %w(Copepoda 33198 /index.php/Taxbrowser_Taxonpage?taxid=979181 class),
      %w(Diplopoda 8732 /index.php/Taxbrowser_Taxonpage?taxid=85 class),
      %w(Diplura 338 /index.php/Taxbrowser_Taxonpage?taxid=734358 class),
      %w(Hexanauplia 194 /index.php/Taxbrowser_Taxonpage?taxid=765970 class),
      %w(Ichthyostraca 226 /index.php/Taxbrowser_Taxonpage?taxid=889450 class),
      %w(Insecta 8862241 /index.php/Taxbrowser_Taxonpage?taxid=82 class),
      %w(Malacostraca 195322 /index.php/Taxbrowser_Taxonpage?taxid=69 class),
      %w(Merostomata 181 /index.php/Taxbrowser_Taxonpage?taxid=74 class),
      %w(Oligostraca_class_incertae_sedis 1 /index.php/Taxbrowser_Taxonpage?taxid=889452 class),
      %w(Ostracoda 7265 /index.php/Taxbrowser_Taxonpage?taxid=80 class),
      %w(Pauropoda 136 /index.php/Taxbrowser_Taxonpage?taxid=493944 class),
      %w(Pentastomida 4 /index.php/Taxbrowser_Taxonpage?taxid=83 class),
      %w(Protura 225 /index.php/Taxbrowser_Taxonpage?taxid=734357 class),
      %w(Pycnogonida 4610 /index.php/Taxbrowser_Taxonpage?taxid=26059 class),
      %w(Remipedia 36 /index.php/Taxbrowser_Taxonpage?taxid=84 class),
      %w(Symphyla 233 /index.php/Taxbrowser_Taxonpage?taxid=80390 class),
      %w(Thecostraca 17856 /index.php/Taxbrowser_Taxonpage?taxid=981579 class)
    ].map {|t| BoldRecord::Taxonomy.new(t[0], t[1], 'https://www.boldsystems.org' + t[2], t[3]) }

    assert_equal taxons, BoldRecord.taxonomy(uri)
  end

  test "taxonomy for insecta bold page" do
    uri = 'file://' + mock_data('bold_taxonomy/insecta.html').to_s
    taxons = [
      %w(Archaeognatha 5001 /index.php/Taxbrowser_Taxonpage?taxid=87070 order),
      %w(Blattodea 36974 /index.php/Taxbrowser_Taxonpage?taxid=532349 order),
      %w(Coleoptera 761682 /index.php/Taxbrowser_Taxonpage?taxid=413 order),
      %w(Dermaptera 3680 /index.php/Taxbrowser_Taxonpage?taxid=160573 order),
      %w(Diptera 3700142 /index.php/Taxbrowser_Taxonpage?taxid=127 order),
      %w(Embioptera 755 /index.php/Taxbrowser_Taxonpage?taxid=152886 order),
      %w(Ephemeroptera 38685 /index.php/Taxbrowser_Taxonpage?taxid=405 order),
      %w(Hemiptera 536724 /index.php/Taxbrowser_Taxonpage?taxid=133 order),
      %w(Hymenoptera 1504011 /index.php/Taxbrowser_Taxonpage?taxid=125 order),
      %w(Lepidoptera 1874195 /index.php/Taxbrowser_Taxonpage?taxid=113 order),
      %w(Mantodea 4256 /index.php/Taxbrowser_Taxonpage?taxid=80725 order),
      %w(Mecoptera 3088 /index.php/Taxbrowser_Taxonpage?taxid=109 order),
      %w(Megaloptera 2646 /index.php/Taxbrowser_Taxonpage?taxid=27042 order),
      %w(Neuroptera 18272 /index.php/Taxbrowser_Taxonpage?taxid=107 order),
      %w(Notoptera 15 /index.php/Taxbrowser_Taxonpage?taxid=762434 order),
      %w(Odonata 37499 /index.php/Taxbrowser_Taxonpage?taxid=105 order),
      %w(Orthoptera 58543 /index.php/Taxbrowser_Taxonpage?taxid=101 order),
      %w(Phasmatodea 2800 /index.php/Taxbrowser_Taxonpage?taxid=115 order),
      %w(Plecoptera 21177 /index.php/Taxbrowser_Taxonpage?taxid=135 order),
      %w(Psocodea 90343 /index.php/Taxbrowser_Taxonpage?taxid=737139 order),
      %w(Raphidioptera 654 /index.php/Taxbrowser_Taxonpage?taxid=194686 order),
      %w(Siphonaptera 3725 /index.php/Taxbrowser_Taxonpage?taxid=91399 order),
      %w(Strepsiptera 988 /index.php/Taxbrowser_Taxonpage?taxid=106972 order),
      %w(Thysanoptera 40647 /index.php/Taxbrowser_Taxonpage?taxid=111 order),
      %w(Trichoptera 81987 /index.php/Taxbrowser_Taxonpage?taxid=99 order),
      %w(Zoraptera 18 /index.php/Taxbrowser_Taxonpage?taxid=533231 order),
      %w(Zygentoma 824 /index.php/Taxbrowser_Taxonpage?taxid=770869 order)
    ].map {|t| BoldRecord::Taxonomy.new(t[0], t[1], 'https://www.boldsystems.org' + t[2], t[3]) }

    assert_equal taxons, BoldRecord.taxonomy(uri)
  end
end
