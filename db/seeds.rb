# # this appears to not work...
# if ENV['RAILS_ENV'] == 'test'
#   puts 'load test data into test database'
#   Dir.chdir(Rails.root.join('test/data')) do
#     cmd = <<~EOF
#     sqlite3 #{Rails.root.join('db/test.sqlite3').to_s} <<ENDCMD
#     delete from occurrences;
#     .mode tabs
#     .import reptilia_gbif_occurrences.tsv occurrences;
#     ENDCMD
#     EOF
#
#     `#{cmd}`
#
#     puts 'done loading data into database'
#
#     # update the metrics
#     # Occurrence.where(species_total_bytes: nil).distinct.pluck(:species_path).each {|p| Species.update_occurrences p }
#   end
# elsif
#   # env for GBIF path?
#   # I think seed is supposed to be database ignorant...
#   raise 'Not yet implemented for dev or prod'
# end
