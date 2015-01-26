Gem::Specification::new do |s|
  s.name = 'oui-offline'
  s.version = '1.2.1'
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
 'ext/mkrf_conf.rb',
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

  s.add_dependency 'sequel', '>= 4', '< 5'
  s.extensions << 'ext/mkrf_conf.rb'

end
.tap {|gem| pk = File.expand_path(File.join('~/.keys', 'gem-private_key.pem')); gem.signing_key = pk if File.exist? pk; gem.cert_chain = ['gem-public_cert.pem']} # pressed firmly by waxseal
