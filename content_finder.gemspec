Gem::Specification.new do |s|
  s.name = 'content_finder'
  s.version = '0.0.1'
  s.licenses = ['MIT']
  s.summary = 'find content in HTML files'
  s.description = 'desc'
  s.authors = ['hydrogen18@gmail.com']  
  s.files = ['lib/content_finder.rb', 'lib/content_finder/cli.rb', 'bin/content_finder']
  s.executables = ['content_finder']
  
  s.add_runtime_dependency 'nokogiri', '~> 1.6'
  s.add_runtime_dependency 'activesupport'
  s.add_runtime_dependency 'null-logger'

  s.add_development_dependency 'minitest'
  s.add_development_dependency 'pry'
end