require 'fileutils'
require 'json'
require 'open-uri'
require 'sequel'

# Organizationally Unique Identifier
module OUI
  extend self

  private

  TABLE = :ouis
  # import data/oui.txt instead of fetching remotely
  IMPORT_LOCAL_TXT_FILE = true
  # use in-memory instead of persistent file
  IN_MEMORY_ONLY = false
  LOCAL_DB = File.expand_path('../../db/oui.sqlite3', __FILE__)
  LOCAL_MANUAL_FILE = File.expand_path('../../data/oui-manual.json', __FILE__)
  if IMPORT_LOCAL_TXT_FILE
    OUI_URL = File.join('data', 'oui.txt')
  else
    OUI_URL = 'http://standards.ieee.org/develop/regauth/oui/oui.txt'
  end
  FIRST_LINE_INDEX = 7
  EXPECTED_DUPLICATES = [0x0001C8, 0x080030]
  LINE_LENGTH = 22

  public

  # @param oui [String,Integer] hex or numeric OUI to find
  # @return [Hash,nil]
  def find(oui)
    update_db unless table? && table.count > 0
    table.where(id: OUI.to_i(oui)).first
  end

  # Converts an OUI string to an integer of equal value
  # @param oui [String,Integer] MAC OUI in hexadecimal formats
  #                             hhhh.hh, hh:hh:hh, hh-hh-hh or hhhhhh
  # @return [Integer] numeric representation of oui
  def to_i(oui)
    return oui if oui.is_a? Integer
    oui = oui.strip.gsub(/[:\- .]/, '')
    return unless oui =~ /[[:xdigit:]]{6}/
    oui.to_i(16)
  end

  # Convert an id to OUI
  # @param oui [String,nil] string to place between pairs of hex digits, nil for none
  # @return [String] hexadecimal format of id
  def to_s(id, sep = '-')
    return id if id.is_a? String
    unless id >= 0x000000 && id <= 0xFFFFFF
      raise ArgumentError, "#{id} is not a valid 24-bit OUI"
    end
    format('%06x', id).scan(/../).join(sep)
  end

  # Release backend resources
  def close_db
    @db = nil
  end

  # Update database from fetched URL
  # @return [Integer] number of unique records loaded
  def update_db
    ## Sequel
    close_db
    drop_table
    create_table
    db.transaction do
      table.delete_sql
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

  HEX_BEGINNING_REGEX = /\A[[:space:]]{2}[[:xdigit:]]{2}-/
  ERASE_LINE = "\b" * LINE_LENGTH
  BLANK_LINE = ' ' * LINE_LENGTH

  def connect_file_db(f)
    FileUtils.mkdir_p(File.dirname(f))
    if RUBY_PLATFORM == 'java'
      Sequel.connect('jdbc:sqlite:'+f) 
    else
      Sequel.sqlite(f)
    end
  end

  def connect_db
    if IN_MEMORY_ONLY
      if RUBY_PLATFORM == 'java'
        Sequel.connect('jdbc:sqlite::memory:')
      else 
        Sequel.sqlite # in-memory sqlite database
      end
    else
      debug "Connecting to db file #{LOCAL_DB}"
      connect_file_db LOCAL_DB
    end
  end

  def db
    @db ||= connect_db
  end

  def table?
    db.tables.include? TABLE
  end

  def table
    db[TABLE]
  end

  def drop_table
    db.drop_table(TABLE) if table? 
  end

  def create_table
    db.create_table TABLE do
      primary_key :id
      String :organization, null: false
      String :address1
      String :address2
      String :address3
      String :country
      index :id
    end
  end

  # @param lines [Array<String>]
  # @return [Array<Array<String>>]
  def parse_lines_into_groups(lines)
    grps, curgrp = [], []
    lines[FIRST_LINE_INDEX..-1].each do |line|
      if !curgrp.empty? && line =~ HEX_BEGINNING_REGEX
        grps << curgrp
        curgrp = []
      end
      line.strip!
      next if line.empty?
      curgrp << line
    end
    grps << curgrp # add last group and return
  end

  # @param g [Array<String>]
  def parse_org(g)
    g[0].split("\t").last
  end

  # @param g [Array<String>]
  def parse_id(g)
    g[1].split(' ')[0].to_i(16)
  end

  MISSING_COUNTRIES = [
    0x000052,
    0x002142,
    0x684CA8
  ]

  COUNTRY_OVERRIDES = {
    0x000052 => 'UNITED STATES',
    0x002142 => 'SERBIA',
    0x684CA8 => 'CHINA'
  }

  def parse_address1(g)
    g[2] if g.length >= 4
  end

  def parse_address2(g, id)
    g[3] if g.length >= 5 || MISSING_COUNTRIES.include?(id)
  end

  def parse_address3(g)
    g[4] if g.length == 6
  end

  # @param g [Array<String>]
  # @param id [Integer]
  def parse_country(g, id)
    c = COUNTRY_OVERRIDES[id] || g[-1]
    c if c !~ /\A\h/
  end

  # @param g [Array<String>]
  def create_from_line_group(g)
    n = g.length
    raise ArgumentError, "Parse error lines: #{n}" unless (2..6).include? n
    id = parse_id(g)
    create_unless_present(id: id, organization: parse_org(g),
                          address1: parse_address1(g),
                          address2: parse_address2(g, id),
                          address3: parse_address3(g),
                          country: parse_country(g, id))
  end

  def fetch
    debug "Fetching #{OUI_URL}"
    open(OUI_URL).read
  end

  def install_manual
    JSON.load(File.read(LOCAL_MANUAL_FILE)).each do |g|
      # convert keys to symbols
      g = g.map { |k, v| [k.to_sym, v] }
      g = Hash[g]
      # convert OUI octets to integers
      g[:id] = OUI.to_i(g[:id])
      create_unless_present(g)
    end
  rescue Errno::ENOENT
  end

  def install_updates
    lines = fetch.split("\n").map { |x| x.sub(/\r$/, '') } 
    parse_lines_into_groups(lines).each_with_index do |group, idx|
      create_from_line_group(group)
      debug "#{ERASE_LINE}Created records #{idx}" if idx % 1000 == 0
    end.count
    debug "#{ERASE_LINE}#{BLANK_LINE}"
  end

  # Expected duplicates are 00-01-C8 (2x) and 08-00-30 (3x)
  def expected_duplicate?(id)
    EXPECTED_DUPLICATES.include? id
  end

  # Has a particular id been added yet?
  def added
    @added ||= {}
  end

  def debug(*args)
    $stderr.puts(*args) if $DEBUG
  end

  def create_unless_present(opts)
    id = opts[:id]
    if added[id]
      unless expected_duplicate? id
        debug "OUI unexpected duplicate #{opts}"
      end
    else
      table.insert(opts)
      # self.create! opts
      added[id] = true
    end
  end
end
