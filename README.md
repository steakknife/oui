# OUI (Organization Unique Identifiers)
## Usage

    OUI.find 'AA-BB-CC'
    OUI.find 'aa.bb.cc'

## Installation
### Bundler Installation

```ruby
gem 'oui', git: 'https://github.com/steakknife/oui.git'
```

### Manual Installation

    cd ${TMP_DIR-/tmp}
    git clone https://github.com/steakknife/oui
    cd oui
    gem build *.gemspec
    gem install *.gem
  

## Data

Database sourced from the public IEEE list, but it can be rebuilt anytime by running `bin/update_db` or `OUI.update_db`

## License

MIT
