require 'sequel'
require 'json'
require 'fileutils'
require 'open-uri'

module OUI
  extend self

  def find(oui)
    ITEMS.where(id: oui_to_i(oui)).first
  end

  def oui_to_i(oui)
    return oui if oui.is_a? Integer
    oui = oui.strip.gsub(/[:\- .]/, '')
    return unless oui =~ /[[:xdigit:]]{6}/
    oui.to_i(16)
  end

  def update_db
  ## Sequel
    DB.drop_table(TABLE) rescue nil
    create_table
    DB.transaction do
      ITEMS.delete_sql
      install_manual
      install_updates
    end

  ## AR
  # self.transaction do
  #   self.delete_all
  #   self.install_manual
  #   self.install_updates
  # end
  end

  private

  TABLE = :ouis
  TEMPORARY = false
  if TEMPORARY
    DB = Sequel.sqlite
  else
    LOCAL_DB = 'db/oui.sqlite3'
    FileUtils.mkdir_p(File.dirname(LOCAL_DB))
    DB = Sequel.sqlite(LOCAL_DB)
  end
  ITEMS = DB[TABLE]
  OUI_URL = 'https://www.ieee.org/netstorage/standards/oui.txt'
  LOCAL_MANUAL_FILE = 'data/oui-manual.json'

  def create_table
    DB.create_table TABLE do
      primary_key :id
      String :organization, null: false
      String :address1
      String :address2
      String :address3
      String :country
      index :id
    end
  end

  def parse_lines_into_groups(lines)
    grps = []
    cur = []
    last_line = lines.count - 1
    hex_beginning_consecutive = 0
    lines.each_with_index do |line, line_no|
      next unless line_no >= 14
      hex_beginning = !!(line =~ /\A[[:space:]]{2}[[:xdigit:]]/)

      if line_no == last_line
        stripped = line.strip
        cur << stripped unless stripped.empty?
        unless cur.empty?
          grps << cur
          cur = []
        end
      elsif hex_beginning && hex_beginning_consecutive == 0
        unless cur.empty?
          grps << cur
          cur = []
        end
        stripped = line.strip
        cur << stripped unless stripped.empty?
      else
        stripped = line.strip
        cur << stripped unless stripped.empty?
      end

      if hex_beginning
        hex_beginning_consecutive += 1
      else
        hex_beginning_consecutive = 0
      end
    end
    grps
  end

  def create_from_line_group(g)
    org = g[0].split("\t").last
    id = g[1].split(' ')[0].to_i(16)
    case g.length
    when 2
      # 0: hex
      # 1: base16
      create_unless_present(id: id, organization: org)

    when 3
      # 0: hex
      # 1: base16
      # 2: country
      create_unless_present(id: id, organization: org, country: g[2])

    when 4
      # 0: hex
      # 1: base16
      # 2: street
      # 3: city state
      # 4: (omitted)
      create_unless_present(id: id, organization: org, address1: g[2],
                            address2: g[3], country: 'UNITED STATES')
    when 5
      # 0: hex
      # 1: base16
      # 2: street
      # 3: city state
      # 4: country
      create_unless_present(id: id, organization: org, address1: g[2],
                            address2: g[3], country: g[4])

    when 6
      # 0: hex
      # 1: base16
      # 2: address1
      # 3: address2
      # 4: address3
      # 5: country
      create_unless_present(id: id, organization: org, address1: g[2],
                            address2: g[3], address3: g[4], country: g[5])

    when 7
      # 0: hex
      # 1: base16
      # 2: address1
      # 3: address2
      # 4: address3
      # 5: address4
      # 6: country
      create_unless_present(id: id, organization: org, address1: g[2],
                            address2: g[3], address3: g[4],
                            address4: g[5], country: g[6])

    else
      raise ArgumentError, "Parse error lines: #{g.length}"
    end
  end


  def fetch
    $stderr.puts "Fetching #{OUI_URL}"
    open(OUI_URL).read
  end

  def install_manual
    return unless File.exist? LOCAL_MANUAL_FILE
    JSON.load(File.read(LOCAL_MANUAL_FILE)).each do |g|
      # convert keys to symbols
      g = Hash[g.map { |k,v| [k.to_sym, v] } ]
      # convert OUI octets to integers
      g[:id] = oui_to_i(g[:id])
      create_unless_present(g)
    end
  end

  def install_updates
    lines = fetch.split("\r\n")
    parse_lines_into_groups(lines).each_with_index do |group, idx|
      create_from_line_group(group)
      $stderr.print ("\b" * 100) + "Created records #{idx}" if idx % 1000 == 0
    end.count
    $stderr.puts ("\b" * 100) + 'Done creating records'
  end

  # Expected duplicates are 00-01-C8 (2x) and 08-00-30 (3x)
  def expected_duplicate?(id)
    id == 456 || id == 524336
  end

  def ids
    @ids ||= {}
  end

  def create_unless_present(opts)
    id = opts[:id]
    if ids[id]
      unless expected_duplicate? id
        $stderr.puts "OUI unexpected duplicate #{opts}"
      end
    else
      OUI::ITEMS.insert(opts)
  #    self.create! opts
      ids[id] = true
    end
  end


end
