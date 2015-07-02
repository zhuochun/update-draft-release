Gem::Specification.new do |s|
  s.name        = 'update-draft-release'
  s.version     = '0.1.4'
  s.authors     = ['Wang Zhuochun']
  s.email       = 'zhuochun@hotmail.com'

  s.summary     = 'Update Draft Release'
  s.description = 'Add your lastest commit to your GitHub repo\'s draft release'
  s.homepage    = 'https://github.com/zhuochun/update-draft-release'
  s.license     = 'MIT'

  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_runtime_dependency 'octokit', '~> 3.0'
  s.add_runtime_dependency 'netrc', '~> 0.10.3'

  s.add_development_dependency 'rake', '~> 10.4.2'
  s.add_development_dependency 'rspec', '~> 3.2.0'
end
