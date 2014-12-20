Gem::Specification::new do |s|
  s.name = 'oui'
  s.version = '0.0.1'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Organization Unique Idenitfier (OUI)'
  s.description = 'Organization Unique Idenitfier (OUI) offline database'
  s.license = 'MIT'

  s.files =
['Gemfile',
 'README.md',
 'bin/lookup',
 'bin/update_db',
 'data/oui-manual.json',
 'db/oui.sqlite3',
 'lib/oui.rb',
 'oui.gemspec',
]

  s.require_path = 'lib'

  s.author = 'Barry Allard'
  s.email = 'barry.allard [at] gmail [dot] com'
  s.homepage = 'https://github.com/steakknife/oui'

  s.add_dependency 'sqlite3', '~> 0'
  s.add_dependency 'sequel', '~> 0'
end
