Gem::Specification.new do |s|
  s.name        = 'vaextractor'
  s.version     = '0.0.1'
  s.date        = '2016-10-03'
  s.summary     = "Rule based NLP library to extract visual acuities"
  s.description = <<-EOF
vaextractor uses rule-based NLP strategy to extract Snellen visual acuities
from unstructured ophthalmology clinical notes.
EOF
  s.authors     = ["Aaron Y. Lee MD MSCI"]
  s.email       = 'aaronylee@gmail.com'
  s.files       = ["lib/vaextractor.rb"]
  s.homepage    = 'http://github.org/ayl/vaextractor'
  s.license     = 'GNU GPLv3'
  s.add_runtime_dependency  'textoken', '1.1.2'
  s.add_development_dependency  'minitest', '5.9.1'
end
