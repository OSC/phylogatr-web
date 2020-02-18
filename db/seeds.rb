
Dir.chdir('/fs/scratch/PAS1604/genbank') do
  ActiveRecord::Base.connection.execute('load data local infile "gbif_occurrences_final.tsv" into table occurrences;')
  ActiveRecord::Base.connection.execute('load data local infile "genes.tsv" into table genes;')
end
