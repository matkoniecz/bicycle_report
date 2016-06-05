Gem::Specification.new do |s|
  s.name        = 'bicycle_report'
  s.version     = '0.0.0'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Mateusz Konieczny']
  s.email       = ['matkoniecz@gmail.com']
  s.homepage    = 'https://github.com/matkoniecz/bicycle_report'
  s.summary     = 'Generates bicycle reports from OSM data.'
  s.description = 'Generates bicycle reports from OSM data.'
  s.license     = 'GPL v3'

  s.required_rubygems_version = '>= 1.8.23'

  s.add_dependency 'i18n', '~>0'
  s.add_dependency 'leafleter', '~>0'
  s.add_dependency 'overhelper', '~>0'
  s.add_dependency 'rest-client', '~>1'
  s.add_dependency 'persistent-cache', '~>0'
  #digest/sha1 is from stdlib

  # If you need to check in files that aren't .rb files, add them here
  s.files        = Dir['{lib}/**/*.rb', 'bin/*', '*.txt', '*.md']
  s.require_path = 'lib'
end

=begin
how to release new gem version:

gem build bicycle_report.gemspec
gem install bicycle_report-*.*.*.gem
gem push bicycle_report-*.*.*.gem
=end