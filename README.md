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
### Gem (insecure installation)

```shell
[sudo] gem install oui-offline
```
### Gem (secure installation)

```shell
[sudo] gem cert --add <(curl -L https://gist.github.com/steakknife/5333881/raw/gem-public_cert.pem) # add my cert (do once)
[sudo] gem install -P HighSecurity oui-offline
```

See also: [waxseal](https://github.com/steakknife/waxseal)

### Bundler Installation

```ruby
gem 'oui-offline'
```

### Manual Installation

    cd ${TMP_DIR-/tmp}
    git clone https://github.com/steakknife/oui
    cd oui
    gem build *.gemspec
    gem install *.gem
  

## Lookup an OUI from CLI

`oui lookup ABCDEF`

## Data

Database sourced from the public IEEE list, but it can be rebuilt anytime by running `oui update` or `OUI.update_db`

## License

MIT
