class GenesController < ApplicationController
  def multiple_symbols
    @limit = (params[:limit] && params[:limit].to_i) || 100
    @genes = (Gene.where.not(symbol: "")
                  .where.not(name: "")
                  .group(:symbol, :name)
                  .order('count_id desc')
                  .count('id')
             ).group_by {|k,v| k[1]}
              .transform_values {|v| v.select {|mapping| mapping[1] > @limit }}
              .select {|k,v| v.count > 1 }

    # structure is:
    # {
    #   "cytochrome-oxidase-subunit-1"=>[
    #     [["COI", "cytochrome-oxidase-subunit-1"], 1196941],
    #     [["CO1", "cytochrome-oxidase-subunit-1"], 2496],
    #     [["COX1", "cytochrome-oxidase-subunit-1"], 2479]
    #   ],
    # }
  end

  def product_and_symbol
    # all genes that have product and symbol specified (limited by 300)
    @limit = (params[:limit] && params[:limit].to_i) || 300
    @genes = (Gene.where.not(symbol: "")
                  .where.not(name: "")
                  .group(:symbol, :name)
                  .order('count_id desc')
                  .count('id')
             ).select {|k,v| v > @limit }
    # structure is
    # {
    #   ["COI", "cytochrome-oxidase-subunit-1"]=>1196941,
    #   ["COI", "cytochrome-oxidase-subunit-I"]=>64034,
    #   ["RBCL", "ribulose-1,5-bisphosphate-carboxylase-oxygenase-large-subunit"]=>41891,
    #   ["CYTB", "cytochrome-b"]=>27116,
    # }
  end

  def product_without_symbol
    @limit = (params[:limit] && params[:limit].to_i) || 100

    @genes = (Gene.where(symbol: "")
                  .where.not(name: "")
                  .group(:name)
                  .order('count_id desc')
                  .count('id')
             ).select {|k,v| v > @limit }
  end

  def all_symbols
    @limit = (params[:limit] && params[:limit].to_i) || 300
    @genes = (Gene.where.not(symbol: "")
                  .group(:symbol)
                  .order('count_id desc')
                  .count('id')
             ).select {|k,v| v > @limit }
  end
end
