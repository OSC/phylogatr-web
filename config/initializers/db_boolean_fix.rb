# rails 6.0 uses integers 0 and 1 for booleans instead of characters
# 't' and 'f'
Rails.application.config.after_initialize do
  if ActiveRecord::Base.connection.table_exists? 'species'
    Species.where("aligned = 't'").update_all(aligned: 1)
    Species.where("aligned = 'f'").update_all(aligned: 0)
  end
end
