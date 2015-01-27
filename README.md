[![Build Status](https://travis-ci.org/steakknife/oui.svg)](https://travis-ci.org/steakknife/oui)
# OUI (Organizationally Unique Identifiers)

The 24-bit prefix of MAC / EUI-\* addresses.

This is a Ruby library and CLI tool `oui`

## Usage

```ruby
> OUI.find 'AA-BB-CC'
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
```

## CLI usage

```text
  Usage: oui lookup [options...] oui+     # get corp name, oui in 24-bit oui in hex format

             -j JSON verbose output
             -r Ruby verbose output
             -y YAML verbose output

         oui update                       # update oui internal db from ieee.org
```

## Installation
### Gem (insecure installation)

```shell
[sudo] gem install oui-offline
```
### Gem (secure installation)

```shell
[sudo] gem cert --add <(curl -L https://gist.github.com/steakknife/5333881/raw/gem-public_cert.pem) # add my cert (do once)
[sudo] gem install -P MediumSecurity oui-offline
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

## Data source

Database sourced from the public IEEE list, but it can be rebuilt anytime by running `oui update` or `OUI.update_db`
The few duplicates that are of multiple entities per OUI instead choose the first registration.

## Unregistered OUIs

Place custom/unregistered OUIs in `data/oui-manual.json` and re-run `oui update` or `OUI.update_db`.  Feel free to submit a PR to update these permanently.

## Return format

`OUI.find('00-00-00')` returns a hash like this:

```ruby
{:id            => 0,
 :organization  => "XEROX CORPORATION",
 :address1      => "M/S 105-50C",
 :address2      => "800 PHILLIPS ROAD",
 :address3      => "WEBSTER NY 14580",
 :country       => "UNITED STATES"}
```


The `id` column is a stable, reversible conversion of the OUI as follows: the hexadecimal value of the OUI) to unsigned integer in network order (id).

- Use `OUI.oui_to_i('aa-bb-cc')` to obtain an `id` from an OUI
- Use `OUI.to_s(12345)` to do the inverse, obtain an OUI from an `id`

## Supported Ruby Engines

- JRuby
- Ruby 1.9.3+ (until February 2015), 2.*

## Tested Ruby Engines

- JRuby
    - 1.7.*
- Ruby (MRI)
    - ruby-head
    - 2.2.0
    - 2.1.5
    - 2.0.0
    - 1.9.3
    - jruby-19mode
    - Rubinius (rbx)

## Thanks

### **Jason Kendall** - Elasticsearch

## License

MIT
