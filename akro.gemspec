Gem::Specification.new do |spec|
  spec.name = 'akro'
  spec.version = '0.0.0'
  spec.license = 'MIT'
  spec.summary = 'Akro build system - extends rake for effective C++ builds'
  spec.executables = ['akro']
  spec.files = ['bin/akro', 'lib/akro.rb', 'lib/akrobuild.rake']
  spec.authors = ['Vlad Petric']
  spec.add_dependency 'rake', '~> 11.1'
end
