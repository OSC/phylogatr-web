class OccurrencePostRecord
  include ActiveModel::Model

  #FIXME: OccurrenceRecord::INPUT_HEADERS and OccurrenceRecord::OUTPUT_HEADERS
  HEADERS=[:species_path, *OccurrenceRecord::HEADERS, :flag, :different_genbank_species, :genes]

  HEADERS.each do |h|
    attr_accessor h
  end

  def self.handle_null(column)
    if using_mysql_adapter?
      column.presence || '\N'
    else
      column
    end
  end

  def self.using_mysql_adapter?
    ActiveRecord::Base.connection.adapter_name == 'Mysql2'
  end

  def self.using_sqlite_adapter?
    ActiveRecord::Base.connection.adapter_name == 'SQLite'
  end
end
