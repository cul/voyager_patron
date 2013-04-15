require 'helper'

class TestVoyagerPatron < MiniTest::Unit::TestCase
  def test_that_testing_works
    assert true
  end

  def test_that_objects_load
    assert VoyagerPatron::Action
  end
  
  def test_patron_load
    patron = VoyagerPatron::Patron.new(SERVER, {:last_name => "Stuart", :institution_id => "jws2135"})
    patron.load_account
    #raise patron.account.inspect

  end
end
