require 'minitest/autorun'

require 'oui'
require 'fileutils'

class TestOUI < Minitest::Test
  DB_FILE = 'db/oui.sqlite3'

  def setup
    @xerox = {id: 0,
    organization: 'XEROX CORPORATION',
        address1: 'M/S 105-50C',
        address2: '800 PHILLIPS ROAD',
        address3: 'WEBSTER NY 14580',
         country: 'UNITED STATES'}

    @dell = {id: 54032,
   organization: 'Dell, Inc., for Dell Compellent Storage products',
       address1: nil,
       address2: nil,
       address3: nil,
        country: nil}
  end

  def test_update_db
    ::FileUtils.rm_f DB_FILE
    OUI.update_db
    assert_equal ::File.exists?(DB_FILE), true
  end

  def test_lookup
    assert_equal OUI.find('000000'), @xerox
    assert_equal OUI.find('00-00-00'), @xerox
    assert_equal OUI.find('00:00:00'), @xerox
    assert_equal OUI.find('000.000'), @xerox
  end

  def test_convert
    assert_equal OUI.to_s(OUI.to_i('000000')), '00-00-00'
    assert_equal OUI.to_s(OUI.to_i('000000'), nil), '000000'
    assert_equal OUI.to_s(OUI.to_i('000000'), '.'), '00.00.00'
  end

  def test_manual_data
    assert_equal OUI.find('00:D3:10'), @dell
  end
end
