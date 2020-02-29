Gem::Specification.new do |spec|
  spec.name = 'akro'
  spec.email = 'vlad@impaler.org'
  spec.version = '0.0.8'
  spec.license = 'MIT'
  spec.summary = 'Akro build - an extreme C++ build system'
  spec.executables = ['akro']
  spec.files = ['bin/akro', 'lib/akro.rb', 'lib/akrobuild.rake']
  spec.authors = ['Vlad Petric']
  spec.add_dependency 'rake', '>= 12.3.3'
  spec.required_ruby_version = ">= 2.0"
  spec.homepage = 'http://drpetric.blogspot.com/'
end
