require 'test_helper'

class BoldRecordTest < ActiveSupport::TestCase
  #FIXME: there is fixture_file('') so maybe
  # the fixtures dir is still the correct place?
  #

  test "taxonomy for home bold page" do
    uri = 'file://' + mock_data('bold_taxonomy/home.html').to_s
    taxons = [
      %w(Acanthocephala 2306 /index.php/Taxbrowser_Taxonpage?taxid=11),
      %w(Acoelomorpha 20 /index.php/Taxbrowser_Taxonpage?taxid=296140),
      %w(Annelida 102966 /index.php/Taxbrowser_Taxonpage?taxid=2),
      %w(Arthropoda 10058285 /index.php/Taxbrowser_Taxonpage?taxid=20),
      %w(Brachiopoda 310 /index.php/Taxbrowser_Taxonpage?taxid=9),
      %w(Bryozoa 4133 /index.php/Taxbrowser_Taxonpage?taxid=7),
      %w(Chaetognatha 1743 /index.php/Taxbrowser_Taxonpage?taxid=13),
      %w(Chordata 839204 /index.php/Taxbrowser_Taxonpage?taxid=18),
      %w(Cnidaria 29865 /index.php/Taxbrowser_Taxonpage?taxid=3),
      %w(Ctenophora 511 /index.php/Taxbrowser_Taxonpage?taxid=249225),
      %w(Cycliophora 326 /index.php/Taxbrowser_Taxonpage?taxid=79455),
      %w(Echinodermata 57293 /index.php/Taxbrowser_Taxonpage?taxid=4),
      %w(Entoprocta 65 /index.php/Taxbrowser_Taxonpage?taxid=299518),
      %w(Gastrotricha 1351 /index.php/Taxbrowser_Taxonpage?taxid=392665),
      %w(Gnathostomulida 24 /index.php/Taxbrowser_Taxonpage?taxid=78956),
      %w(Hemichordata 234 /index.php/Taxbrowser_Taxonpage?taxid=21),
      %w(Kinorhyncha 720 /index.php/Taxbrowser_Taxonpage?taxid=392666),
      %w(Mollusca 243013 /index.php/Taxbrowser_Taxonpage?taxid=23),
      %w(Nematoda 34770 /index.php/Taxbrowser_Taxonpage?taxid=19),
      %w(Nematomorpha 401 /index.php/Taxbrowser_Taxonpage?taxid=261851),
      %w(Nemertea 5669 /index.php/Taxbrowser_Taxonpage?taxid=497163),
      %w(Onychophora 1393 /index.php/Taxbrowser_Taxonpage?taxid=10),
      %w(Phoronida 160 /index.php/Taxbrowser_Taxonpage?taxid=370374),
      %w(Placozoa 20 /index.php/Taxbrowser_Taxonpage?taxid=321215),
      %w(Platyhelminthes 38589 /index.php/Taxbrowser_Taxonpage?taxid=5),
      %w(Porifera 7808 /index.php/Taxbrowser_Taxonpage?taxid=24818),
      %w(Priapulida 148 /index.php/Taxbrowser_Taxonpage?taxid=392644),
      %w(Rhombozoa 48 /index.php/Taxbrowser_Taxonpage?taxid=531453),
      %w(Rotifera 12761 /index.php/Taxbrowser_Taxonpage?taxid=16),
      %w(Sipuncula 1318 /index.php/Taxbrowser_Taxonpage?taxid=15),
      %w(Tardigrada 2908 /index.php/Taxbrowser_Taxonpage?taxid=26033),
      %w(Xenacoelomorpha 18 /index.php/Taxbrowser_Taxonpage?taxid=531452),
      %w(Bryophyta 21899 /index.php/Taxbrowser_Taxonpage?taxid=176192),
      %w(Chlorophyta 14519 /index.php/Taxbrowser_Taxonpage?taxid=112296),
      %w(Lycopodiophyta 1215 /index.php/Taxbrowser_Taxonpage?taxid=38696),
      %w(Magnoliophyta 366736 /index.php/Taxbrowser_Taxonpage?taxid=12),
      %w(Pinophyta 7068 /index.php/Taxbrowser_Taxonpage?taxid=251587),
      %w(Pteridophyta 11393 /index.php/Taxbrowser_Taxonpage?taxid=38074),
      %w(Rhodophyta 54630 /index.php/Taxbrowser_Taxonpage?taxid=48327),
      %w(Ascomycota 98397 /index.php/Taxbrowser_Taxonpage?taxid=34),
      %w(Basidiomycota 66488 /index.php/Taxbrowser_Taxonpage?taxid=23675),
      %w(Chytridiomycota 293 /index.php/Taxbrowser_Taxonpage?taxid=23691),
      %w(Glomeromycota 3529 /index.php/Taxbrowser_Taxonpage?taxid=85867),
      %w(Myxomycota 235 /index.php/Taxbrowser_Taxonpage?taxid=83947),
      %w(Zygomycota 3273 /index.php/Taxbrowser_Taxonpage?taxid=23738),
      %w(Chlorarachniophyta 67 /index.php/Taxbrowser_Taxonpage?taxid=316986),
      %w(Ciliophora 788 /index.php/Taxbrowser_Taxonpage?taxid=72834),
      %w(Heterokontophyta 7209 /index.php/Taxbrowser_Taxonpage?taxid=53944),
      %w(Pyrrophycophyta 2337 /index.php/Taxbrowser_Taxonpage?taxid=317010)
    ].map {|t| BoldRecord::Taxonomy.new(*t) }

    assert_equal taxons, BoldRecord.taxonomy(uri)
  end

  test "taxonomy for arthropoda bold page" do
    uri = 'file://' + mock_data('bold_taxonomy/arthropoda.html').to_s
    taxons = [
      %w(Acrothoracica 4 /index.php/Taxbrowser_Taxonpage?taxid=987854),
      %w(Arachnida 460142 /index.php/Taxbrowser_Taxonpage?taxid=63),
      %w(Branchiopoda 19994 /index.php/Taxbrowser_Taxonpage?taxid=68),
      %w(Cephalocarida 27 /index.php/Taxbrowser_Taxonpage?taxid=73),
      %w(Chilopoda 4662 /index.php/Taxbrowser_Taxonpage?taxid=75),
      %w(Collembola 193826 /index.php/Taxbrowser_Taxonpage?taxid=372),
      %w(Copepoda 33198 /index.php/Taxbrowser_Taxonpage?taxid=979181),
      %w(Diplopoda 8732 /index.php/Taxbrowser_Taxonpage?taxid=85),
      %w(Diplura 338 /index.php/Taxbrowser_Taxonpage?taxid=734358),
      %w(Hexanauplia 194 /index.php/Taxbrowser_Taxonpage?taxid=765970),
      %w(Ichthyostraca 226 /index.php/Taxbrowser_Taxonpage?taxid=889450),
      %w(Insecta 8862241 /index.php/Taxbrowser_Taxonpage?taxid=82),
      %w(Malacostraca 195322 /index.php/Taxbrowser_Taxonpage?taxid=69),
      %w(Merostomata 181 /index.php/Taxbrowser_Taxonpage?taxid=74),
      %w(Oligostraca_class_incertae_sedis 1 /index.php/Taxbrowser_Taxonpage?taxid=889452),
      %w(Ostracoda 7265 /index.php/Taxbrowser_Taxonpage?taxid=80),
      %w(Pauropoda 136 /index.php/Taxbrowser_Taxonpage?taxid=493944),
      %w(Pentastomida 4 /index.php/Taxbrowser_Taxonpage?taxid=83),
      %w(Protura 225 /index.php/Taxbrowser_Taxonpage?taxid=734357),
      %w(Pycnogonida 4610 /index.php/Taxbrowser_Taxonpage?taxid=26059),
      %w(Remipedia 36 /index.php/Taxbrowser_Taxonpage?taxid=84),
      %w(Symphyla 233 /index.php/Taxbrowser_Taxonpage?taxid=80390),
      %w(Thecostraca 17856 /index.php/Taxbrowser_Taxonpage?taxid=981579)
    ].map {|t| BoldRecord::Taxonomy.new(*t) }

    assert_equal taxons, BoldRecord.taxonomy(uri)
  end

  test "taxonomy for insecta bold page" do
    uri = 'file://' + mock_data('bold_taxonomy/insecta.html').to_s
    taxons = [
      %w(Archaeognatha 5001 /index.php/Taxbrowser_Taxonpage?taxid=87070),
      %w(Blattodea 36974 /index.php/Taxbrowser_Taxonpage?taxid=532349),
      %w(Coleoptera 761682 /index.php/Taxbrowser_Taxonpage?taxid=413),
      %w(Dermaptera 3680 /index.php/Taxbrowser_Taxonpage?taxid=160573),
      %w(Diptera 3700142 /index.php/Taxbrowser_Taxonpage?taxid=127),
      %w(Embioptera 755 /index.php/Taxbrowser_Taxonpage?taxid=152886),
      %w(Ephemeroptera 38685 /index.php/Taxbrowser_Taxonpage?taxid=405),
      %w(Hemiptera 536724 /index.php/Taxbrowser_Taxonpage?taxid=133),
      %w(Hymenoptera 1504011 /index.php/Taxbrowser_Taxonpage?taxid=125),
      %w(Lepidoptera 1874195 /index.php/Taxbrowser_Taxonpage?taxid=113),
      %w(Mantodea 4256 /index.php/Taxbrowser_Taxonpage?taxid=80725),
      %w(Mecoptera 3088 /index.php/Taxbrowser_Taxonpage?taxid=109),
      %w(Megaloptera 2646 /index.php/Taxbrowser_Taxonpage?taxid=27042),
      %w(Neuroptera 18272 /index.php/Taxbrowser_Taxonpage?taxid=107),
      %w(Notoptera 15 /index.php/Taxbrowser_Taxonpage?taxid=762434),
      %w(Odonata 37499 /index.php/Taxbrowser_Taxonpage?taxid=105),
      %w(Orthoptera 58543 /index.php/Taxbrowser_Taxonpage?taxid=101),
      %w(Phasmatodea 2800 /index.php/Taxbrowser_Taxonpage?taxid=115),
      %w(Plecoptera 21177 /index.php/Taxbrowser_Taxonpage?taxid=135),
      %w(Psocodea 90343 /index.php/Taxbrowser_Taxonpage?taxid=737139),
      %w(Raphidioptera 654 /index.php/Taxbrowser_Taxonpage?taxid=194686),
      %w(Siphonaptera 3725 /index.php/Taxbrowser_Taxonpage?taxid=91399),
      %w(Strepsiptera 988 /index.php/Taxbrowser_Taxonpage?taxid=106972),
      %w(Thysanoptera 40647 /index.php/Taxbrowser_Taxonpage?taxid=111),
      %w(Trichoptera 81987 /index.php/Taxbrowser_Taxonpage?taxid=99),
      %w(Zoraptera 18 /index.php/Taxbrowser_Taxonpage?taxid=533231),
      %w(Zygentoma 824 /index.php/Taxbrowser_Taxonpage?taxid=770869)
    ].map {|t| BoldRecord::Taxonomy.new(*t) }

    assert_equal taxons, BoldRecord.taxonomy(uri)
  end
end
