# OUI (Organizationally Unique Identifiers)
## Usage

    >OUI.find 'AA-BB-CC'
    => nil
    > OUI.find '00:0c:85'
    => {
                  :id => 3205,
        :organization => "CISCO SYSTEMS, INC.",
            :address1 => "170 W. TASMAN DRIVE",
            :address2 => "M/S SJA-2",
            :address3 => "SAN JOSE CA 95134-1706",
             :country => "UNITED STATES"
    }

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
