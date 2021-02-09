class BoldRecord
  include ActiveModel::Model
  include ActiveModel::Validations

  HEADERS = %i(
    process_id
    record_id
    catalog_number
    field_number
    taxon_phylum
    taxon_class
    taxon_order
    taxon_family
    taxon_genus
    taxon_species
    taxon_subspecies
    lat
    lng
    gene_symbol
    accession
    sequence
  )


  HEADERS.each do |h|
    attr_accessor h
  end

  def gene_symbol_mapped
    @gene_symbol_mapped ||= lookup_gene_symbol(self.gene_symbol)
  end

  def fasta_sequence
    accession = self.accession.presence || '00000000'
    ">#{accession}_#{self.process_id}\n#{self.sequence}\n"
  end

  def self.line_count(path)
    File.foreach(path).reduce(0) {|count, line| count+1 }
  end

  private

  GENE_SYMBOL_LOOKUP = {
        'COI-5P' => 'COI',
        'RBCLA' => 'RBCL',
        'MATK' => 'MATK',
        'ITS2' => 'ITS',
        'ITS' => 'ITS',
        'RBCL' => 'RBCL',
        '16S' => '16S',
        'ITS1' => 'ITS',
        'TRNH-PSBA' => 'TRN',
        '28S' => '28S',
        '5-8S' => '58S',
        'COI-3P' => 'COI',
        'TRNL-F' => 'TRN',
        '12S' => '12S',
        'CYTB' => 'CYTB',
        '18S' => '18S',
        'RPOC1' => 'RPOC1',
        'RHO' => 'RHO',
        'TUFA' => 'TUFA',
        'H3' => 'H3',
        '28S-D2' => '28S',
        'UPA' => 'UPA',
        'RPOB' => 'RPOB',
        'DBY-EX7-8' => 'DBY',
        'D-LOOP' => 'DLOOP',
        'PSBA' => 'PSBA',
        'ND2' => 'ND2',
        'YCF1' => 'YCF1',
        '28S-D9-D10' => '28S',
        'TRND-TRNY-TRNE' => 'TRN',
        'RAG1' => 'RAG1',
        'RAG2' => 'RAG2',
        '28S-D1-D2' => '28S',
        'MC1R' => 'MC1R',
        'MB2-EX2-3' => 'MB2',
        'RNF213' => 'RNF',
        'H4' => 'H4',
        'CHD-Z' => 'CHD-Z',
        'VDAC' => 'VDAC',
        'DYN' => 'DYN',
        'PSA' => 'PSAA',
        'AOX-FMT' => 'AOX',
        'TRNK' => 'TRN',
        'ND4L-MSH' => 'ND4',
        'TYR' => 'TYR',
        'ATP6-ATP8' => 'ATP',
        'PLAGL2' => 'PFLAG',
        'EF2' => 'EF2',
        'NUCLSU' => 'LSU',
        'PSBA-3P' => 'PSBA',
        'PETD-INTRON' => 'PETD',
        '28S-D2-D3' => '28S',
        'MATK-LIKE' => 'MATK',
        'ADR' => 'ADR',
        'FL-COI' => 'COI',
        'RBCL-LIKE' => 'RBCL',
        '18S-3P' => '18S',
        'NGFB' => 'NGFB',
        'ATP6' => 'ATP',
        'PSAB' => 'PSAB',
        '18S-V4' => '18S',
        'COXIII' => 'COIII',
        'COII' => 'COII',
        'ND4' => 'ND4',
        'RBCL-5P' => 'RBCL'
    }

  GENE_SYMBOL_NOT_SURE = %w(
      COII-COI
      16S-ND2
      ND6-ND3
      atpB-rbcL
      atp6-atp8
      markercode
      matK-trnK
      R35
    )
  GENE_SYMBOL_IGNORE = %w(
      COI-LIKE
      TMO-4C4
      PKD1
      S7
      RPB2
      RPB1
      EF1-alpha
      COI-PSEUDO
      COI-NUMT
    )




  def lookup_gene_symbol(gene_symbol)
    s = gene_symbol.to_s.strip.upcase

    if s.present? && ! (GENE_SYMBOL_NOT_SURE.include?(s) || GENE_SYMBOL_IGNORE.include?(s))
      GENE_SYMBOL_LOOKUP[s]
    end
  end
end
