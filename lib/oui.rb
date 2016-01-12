autoload :FileUtils, 'fileutils'
autoload :JSON, 'json'
require 'monitor'
require 'open-uri'

require 'sequel'

# Organizationally Unique Identifier
module OUI
  extend self

  private

  DEBUGGING_DEFAULT = false
  TABLE = :ouis
  # import data/oui.txt instead of fetching remotely
  IMPORT_LOCAL_TXT_FILE_DEFAULT = false
  # use in-memory instead of persistent file
  IN_MEMORY_ONLY_DEFAULT = false
  ROOT = File.expand_path(File.join('..', '..'), __FILE__)
  LOCAL_DB_DEFAULT = File.join(ROOT, 'db', 'oui.sqlite3')
  LOCAL_TXT_FILE = File.join(ROOT, 'data', 'oui.txt')
  REMOTE_TXT_URI = 'http://standards.ieee.org/develop/regauth/oui/oui.txt'
  LOCAL_MANUAL_FILE = File.join(ROOT, 'data', 'oui-manual.json')
  FIRST_LINE_INDEX = 7
  EXPECTED_DUPLICATES = [0x0001C8, 0x080030]
  LINE_LENGTH = 22
  HEX_BEGINNING_REGEX = /\A[[:space:]]*[[:xdigit:]]{2}-[[:xdigit:]]{2}-[[:xdigit:]]{2}[[:space:]]*\(hex\)/
  ERASE_LINE = "\b" * LINE_LENGTH
  BLANK_LINE = ' ' * LINE_LENGTH

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

  public

  @@local_db = LOCAL_DB_DEFAULT

  def local_db
    @@local_db
  end

  def local_db=(v)
    @@local_db = v || LOCAL_DB_DEFAULT
  end


  @@debugging = DEBUGGING_DEFAULT

  def debugging
    @@debugging
  end

  def debugging=(v)
    @@debugging = (v.nil?) ? DEBUGGING_DEFAULT : v
  end


  @@import_local_txt_file = IMPORT_LOCAL_TXT_FILE_DEFAULT

  def import_local_txt_file
    @@import_local_txt_file
  end

  def import_local_txt_file=(v)
    @@import_local_txt_file = (v.nil?) ? IMPORT_LOCAL_TXT_FILE_DEFAULT : v
  end


  @@in_memory_only = IN_MEMORY_ONLY_DEFAULT

  def in_memory_only
    @@in_memory_only
  end

  def in_memory_only=(v)
    if v != @@in_memory_only
      @@in_memory_only = (v.nil?) ? IN_MEMORY_ONLY_DEFAULT : v
      close_db
    end
  end

  # @param oui [String,Integer] hex or numeric OUI to find
  # @return [Hash,nil]
  def find(oui)
    semaphore.synchronize do
      update_db unless table? && table.count > 0
      r = table.where(id: self.to_i(oui)).first
      r.delete :create_table if r # not sure why this is here, but nuking it
      r
    end
  end

  # Converts an OUI string to an integer of equal value
  # @param oui [String,Integer] MAC OUI in hexadecimal formats
  #                             hhhh.hh, hh:hh:hh, hh-hh-hh or hhhhhh
  # @return [Integer] numeric representation of oui
  def to_i(oui)
    return oui if oui.is_a? Integer
    oui = oui.strip.gsub(/[:\- .]/, '')
    if oui =~ /([[:xdigit:]]{6})/
      $1.to_i(16)
    end
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

  @@db = nil
  # Release backend resources
  def close_db
    semaphore.synchronize do
      debug 'Closing database'
      if @@db 
        @@db.disconnect
        @@db = nil
      end
    end
  end

  def clear_table
    debug 'clear_table'
    table.delete_sql
  end

  # Update database from fetched URL
  # @param [Boolean] whether to connect to the network or not
  # @return [Integer] number of unique records loaded
  def update_db(local = nil, db_file = nil)
    semaphore.synchronize do
      debug "update_db(local = #{local}, db_file = #{db_file})"
      close_db
      old_import_local_txt_file = self.import_local_txt_file
      self.import_local_txt_file = local
      old_local_db = self.local_db
      self.local_db = db_file
      ## Sequel
      debug '--- close db ---'
      debug '--- close db ---'
      debug '--- drop table ---'
      drop_table
#      debug '--- drop table ---'
#      debug '--- create table ---'
      create_table
#      debug '--- create table ---'
      db.transaction do
        debug '--- clear table ---'
        clear_table
        debug '--- clear table ---'
        debug '--- install manual ---'
        install_manual
        debug '--- install manual ---'
        debug '--- install updates ---'
        install_updates
        debug '--- install updates ---'
      end
      debug '--- close db ---'
      close_db
      debug '--- close db ---'

      self.local_db = old_local_db
      self.import_local_txt_file = old_import_local_txt_file
      ## AR
      # self.transaction do
      #   self.delete_all
      #   self.install_manual
      #   self.install_updates
      # end
      debug "update_db(local = #{local}, db_file = #{db_file}) finish"
    end
  end
  
  private

  def connect_file_db(f)
    FileUtils.mkdir_p(File.dirname(f))
    if RUBY_PLATFORM == 'java'
      u = 'jdbc:sqlite:'+f
    else
      u = 'sqlite:'+f
    end
    debug "Connecting to db file #{u}"
    Sequel.connect(u)
  end

  def connect_db
    if in_memory_only
      debug 'Connecting to in-memory database'
      if RUBY_PLATFORM == 'java'
        Sequel.connect('jdbc:sqlite::memory:')
      else 
        Sequel.sqlite # in-memory sqlite database
      end
    else
      connect_file_db local_db
    end
  end

  def db
    @@db ||= connect_db
  end

  def table?
    db.tables.include? TABLE
  end

  def table
    db[TABLE]
  end

  def drop_table
    debug 'drop_table'
    db.drop_table(TABLE) if table? 
  end

  def create_table
#    debug 'create_table'
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
    header = true
    lines.each do |line|
      if header
        if line =~ HEX_BEGINNING_REGEX
          header = false
        else
          next
        end
      end
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
    raise ArgumentError, "Parse error lines: #{n} '#{g}'" unless (2..6).include? n
    id = parse_id(g)
    create_unless_present(id: id, organization: parse_org(g),
                          address1: parse_address1(g),
                          address2: parse_address2(g, id),
                          address3: parse_address3(g),
                          country: parse_country(g, id))
  end

  def fetch
    uri = oui_uri
    $stderr.puts "Fetching #{uri}"
    open(uri).read
  end

  def install_manual
    debug 'install_manual'
    JSON.load(File.read(LOCAL_MANUAL_FILE)).each do |g|
      # convert keys to symbols
      g = g.map { |k, v| [k.to_sym, v] }
      g = Hash[g]
      # convert OUI octets to integers
      g[:id] = self.to_i(g[:id])
      create_unless_present(g)
    end
  rescue Errno::ENOENT
  end

  def install_updates
    debug 'install_updates'
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
    @@added ||= {}
  end

  def debug?
    $DEBUG || debugging || ENV['DEBUG_OUI']
  end

  def debug(*args)
    $stderr.puts(*args) if debug?
  end

  def debug_print(*args)
    $stderr.print(*args) if debug?
  end

  def semaphore
    @@semaphore ||= Monitor.new
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

  def oui_uri
    if import_local_txt_file
      debug 'oui_uri = local'
      LOCAL_TXT_FILE
    else
      debug 'oui_uri = remote'
      REMOTE_TXT_URI
    end
  end
end
