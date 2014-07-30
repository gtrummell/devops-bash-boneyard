require "minitest/autorun"

class TestHwToStackMakr < MiniTest::Unit::TestCase
  def setup
    @ = CashRegister.new
  end
  def no_action_needed
    assert_equal 0, @register.total
  end
end