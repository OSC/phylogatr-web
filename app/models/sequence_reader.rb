class SequenceReader

  def each_sequence(path)
    return to_enum(:each_sequence, path)  unless block_given?

    ff = Bio::GenBank.open(path)
    ff.each_entry do |entry|
      entry.each_cds do |feature|
        yield Sequence.new(entry, feature)
      end
    end
  end

  class Sequence
    attr_reader :gb, :feature

    delegate :accession, :organism, to: :gb

    def initialize(gb, feature)
      @gb = gb
      @feature = feature
    end

    def species
      gb.organism.gsub(/\//, ' ')
    end

    def seq
      gb.seq.splicing(feature.position)
    end

    def gene
      return nil unless feature

      feature.qualifiers.select {|q|
        q.qualifier == "gene" || q.qualifier == "product"
      }.first.value.try {
        gsub(/[ \/ ]/, '-').gsub(/['\.]/, '')
      }

      # feature.assoc.values_at('gene', 'product').compact.first.try {
      #   gsub(/[ \/ ]/, '-').gsub(/['\.]/, '')
      # }
    end
  end
end
