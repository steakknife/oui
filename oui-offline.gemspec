Gem::Specification::new do |s|
  s.name = 'oui-offline'
  s.version = '1.0.0'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Organizationally Unique Idenitfiers (OUI)'
  s.description = 'Organizationally Unique Idenitfiers (OUI) offline database'
  s.license = 'MIT'

  s.files =
['Gemfile',
 'README.md',
 'bin/oui',
 'data/oui-manual.json',
 'db/oui.sqlite3',
 'lib/oui.rb',
 'oui-offline.gemspec',
]
  s.required_ruby_version = '>= 1.9.3'

  s.require_path = 'lib'
  s.executables << 'oui'

  s.author = 'Barry Allard'
  s.email = 'barry.allard [at] gmail [dot] com'
  s.homepage = 'https://github.com/steakknife/oui'
  s.post_install_message = 'Oui!'

  s.add_dependency 'sqlite3', '>= 1.3', '< 2'
  s.add_dependency 'sequel', '>= 4', '< 5'
end
