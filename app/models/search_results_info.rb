class SearchResultsInfo
  include ActiveModel::Serializers::JSON

  attr_accessor :num_species, :estimated_tar_size, :percent_complete, :message

  def attributes=(hash)
    hash.each do |key, value|
      send("#{key}=", value)
    end
  end

  def attributes
    instance_values
  end

  def save(path)
    Pathname.new(path).write(to_json)
  end

  def self.load(path)
    info = self.new
    info.from_json(Pathname.new(path).read)
  end

  def self.build(swpoint, nepoint, taxonomy)
    info = self.new
    info.num_species = self.num_species(swpoint, nepoint, taxonomy)
    info.estimated_tar_size = self.estimated_tar_size(swpoint, nepoint, taxonomy)
    info
  end

  def self.num_species(swpoint, nepoint, taxonomy)
    # FIXME: species table
    # FIXME: taxon_species is preferred to use once fixing pipeline issue
    Occurrence.in_bounds_with_taxonomy(swpoint, nepoint, taxonomy).distinct.count(:species_path)
  end

  def self.estimated_tar_size(swpoint, nepoint, taxonomy)
    Species.where(id:
      Occurrence.in_bounds_with_taxonomy(swpoint, nepoint, taxonomy)
       .where.not(species_id: nil).pluck(:species_id).sort.uniq
    ).sum(:total_bytes)
  end

  # TODO:
  # def seqs_per_species
  #   # FIXME: species table
  #   Occurrence.in_bounds_with_taxonomy(swpoint, nepoint, taxonomy)
  #     .select(:species_path, :species_total_seqs).distinct.as_json
  # end
  class FileUpdaterNull
    def wrote_fasta_files(current)
    end

    def wrote_occurrence_file(current)
    end

    def done
    end
  end

  class FileUpdater
    attr_reader :path, :info, :species_count, :increment

    def initialize(path, species_count)
      @path = path
      @species_count = species_count
      @increment = (species_count/10).to_i
      @info = SearchResultsInfo.load(path)
    end

    def self.load(path, species_count)
      if species_count > 500
        FileUpdater.new(path, species_count)
      else
        FileUpdaterNull.new
      end
    rescue
      Rails.logger.warn("failed to load SearchResultsInfo at path #{path} from SearchResultsInfo::FileUpdater")
      FileUpdaterNull.new
    end

    # fasta files counts for 50%
    def wrote_fasta_files(current)
      if current % increment == 0
        info.attributes = {
          percent_complete: percent(current)/2,
          message: "Wrote fasta files for #{current}/#{species_count} species"
        }
        info.save(path)
      end
    end


    # writing occurrence files counds for 50%
    # add 50 cause this is done after fasta files
    def wrote_occurrence_file(current)
      if current % increment == 0
        info.attributes = {
          percent_complete: 50 + percent(current)/2,
          message: "Wrote occurrence file for #{current}/#{species_count} species"
        }
        info.save(path)
      end
    end

    def percent(current)
      ((100.0*(current.to_f/species_count))).to_i
    end

    def done
      info.attributes = {
        percent_complete: 100,
        message: 'Done writing species data to package.'
      }
      info.save(path)
    end
  end
end
