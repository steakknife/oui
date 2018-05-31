require 'minitest/autorun'

require 'oui'
require 'fileutils'
require 'tempfile'

class TestOUI < Minitest::Test

  def setup
    @tmp_db_file = Tempfile.new('test_oui')
    at_exit { @tmp_db_file.unlink }

    @xerox = {id: 0,
    organization: 'XEROX CORPORATION',
        address1: 'M/S 105-50C',
        address2: 'WEBSTER  NY  14580',
        address3: nil,
         country: 'US'}

    @dell = {id: 54032,
   organization: 'Dell, Inc., for Dell Compellent Storage products',
       address1: nil,
       address2: nil,
       address3: nil,
        country: nil}

    @vmware = {id: 20566,
     organization: 'VMware, Inc.',
         address1: '3401 Hillview Avenue',
         address2: 'PALO ALTO  CA  94304',
         address3: nil,
          country: 'US'}
  end

  def test_update_db
    x = @tmp_db_file.path # Ruby 2.2 GC over-aggressive problem likely
    @tmp_db_file.unlink
    OUI.update_db(true, x)
    assert_equal true, ::File.exists?(x)
  end

  def test_lookup
    assert_equal @xerox, OUI.find('000000')
    assert_equal @xerox, OUI.find('000000FFFFFFFFFFFF')
    assert_equal @xerox, OUI.find('00:00:00:FF:FF:FF')
    assert_equal @vmware, OUI.find('00:50:56:c0:00:01')
    assert_equal @xerox, OUI.find('00-00-00')
    assert_equal @xerox, OUI.find('00:00:00')
    assert_equal @xerox, OUI.find('000.000')
  end

  def test_convert
    assert_equal '00-00-00', OUI.to_s(OUI.to_i('000000'))
    assert_equal '000000', OUI.to_s(OUI.to_i('000000'), nil)
    assert_equal '00.00.00', OUI.to_s(OUI.to_i('000000'), '.')
  end

  def test_manual_data
    assert_equal @dell, OUI.find('00:D3:10')
  end
end
