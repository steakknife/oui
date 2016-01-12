Gem::Specification::new do |s|
  s.name = 'oui-offline'
  s.version = '1.2.7'
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
  s.files << 'data/oui.txt' if File.exist?('data/oui.txt')

  s.required_ruby_version = '>= 1.9.3'

  s.require_path = 'lib'
  s.executables << 'oui'

  s.author = 'Barry Allard'
  s.email = 'barry.allard@gmail.com'
  s.homepage = 'https://github.com/steakknife/oui'
  s.post_install_message = 'Oui!'

  s.add_dependency 'sequel', '~> 4'
  if RUBY_PLATFORM == 'java'
    s.platform = 'java'
    s.add_dependency 'jdbc-sqlite3'
  else
    s.platform = Gem::Platform::RUBY
    s.add_dependency 'sqlite3', '~> 1'
  end
  s.add_development_dependency 'rake', '~> 10'
  s.add_development_dependency 'minitest', '~> 5'
end
.tap {|gem| pk = File.expand_path(File.join('~/.keys', 'gem-private_key.pem')); gem.signing_key = pk if File.exist? pk; gem.cert_chain = ['gem-public_cert.pem']} # pressed firmly by waxseal
