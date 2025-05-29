require 'spec_helper'

describe 'BranchNumber' do
  it 'must test basic' do
    assert_equal OhlohScm::BranchNumber.new('1.1').to_a, [1, 1]
    assert_equal  OhlohScm::BranchNumber.new('1234.1234').to_a, [1234, 1234]
    assert_equal OhlohScm::BranchNumber.new('1.2.3.4').to_a, [1, 2, 3, 4]
  end

  it 'must test simple inherits_from' do
    b = OhlohScm::BranchNumber.new('1.3')

    assert b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.2'))
    assert b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.1'))
    assert b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.3'))

    refute b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.4'))
    refute b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.1.2.1'))
    refute b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.2.2.1'))
    refute b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.3.2.1'))
  end

  it 'must test complex inherits_from' do
    b = OhlohScm::BranchNumber.new('1.3.6.3.2.3')

    assert b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.2'))
    assert b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.1'))
    assert b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.3'))
    assert b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.3.6.1'))
    assert b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.3.6.2'))
    assert b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.3.6.3'))
    assert b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.3.6.3.2.1'))
    assert b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.3.6.3.2.2'))
    assert b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.3.6.3.2.3'))

    refute b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.4'))
    refute b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.1.2.1'))
    refute b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.2.2.1'))
    refute b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.3.2.1'))
    refute b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.3.4.1'))
    refute b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.3.6.1.2.1'))
    refute b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.3.6.4'))
    refute b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.3.6.3.4.1'))
    refute b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.3.6.3.2.2.2.1'))
    refute b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.3.6.3.2.4'))
  end

  it 'must  test primary revision number change' do
    b = OhlohScm::BranchNumber.new('2.3')

    assert b.send(:inherits_from?, OhlohScm::BranchNumber.new('2.2'))
    assert b.send(:inherits_from?, OhlohScm::BranchNumber.new('2.1'))
    assert b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.1'))
    assert b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.9999'))

    refute b.send(:inherits_from?, OhlohScm::BranchNumber.new('2.4'))
    refute b.send(:inherits_from?, OhlohScm::BranchNumber.new('3.1'))
  end

  it 'must test complex primary revision number change' do
    b = OhlohScm::BranchNumber.new('2.3.2.1')

    assert b.send(:inherits_from?, OhlohScm::BranchNumber.new('2.3'))
    assert b.send(:inherits_from?, OhlohScm::BranchNumber.new('2.2'))
    assert b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.1'))
    assert b.send(:inherits_from?, OhlohScm::BranchNumber.new('1.9999'))

    refute b.send(:inherits_from?, OhlohScm::BranchNumber.new('3.1'))
  end

  it 'must test simple on_same_line' do
    b = OhlohScm::BranchNumber.new('1.3')

    assert b.on_same_line?(OhlohScm::BranchNumber.new('1.2'))
    assert b.on_same_line?(OhlohScm::BranchNumber.new('1.1'))
    assert b.on_same_line?(OhlohScm::BranchNumber.new('1.3'))
    assert b.on_same_line?(OhlohScm::BranchNumber.new('1.4'))

    refute b.on_same_line?(OhlohScm::BranchNumber.new('1.1.2.1'))
    refute b.on_same_line?(OhlohScm::BranchNumber.new('1.2.2.1'))
    refute b.on_same_line?(OhlohScm::BranchNumber.new('1.3.2.1'))
  end

  it 'must test complex on_same_line' do
    b = OhlohScm::BranchNumber.new('1.3.6.3.2.3')

    assert b.on_same_line?(OhlohScm::BranchNumber.new('1.1'))
    assert b.on_same_line?(OhlohScm::BranchNumber.new('1.2'))
    assert b.on_same_line?(OhlohScm::BranchNumber.new('1.3'))
    assert b.on_same_line?(OhlohScm::BranchNumber.new('1.3.6.1'))
    assert b.on_same_line?(OhlohScm::BranchNumber.new('1.3.6.2'))
    assert b.on_same_line?(OhlohScm::BranchNumber.new('1.3.6.3'))
    assert b.on_same_line?(OhlohScm::BranchNumber.new('1.3.6.3.2.1'))
    assert b.on_same_line?(OhlohScm::BranchNumber.new('1.3.6.3.2.2'))
    assert b.on_same_line?(OhlohScm::BranchNumber.new('1.3.6.3.2.3'))
    assert b.on_same_line?(OhlohScm::BranchNumber.new('1.3.6.3.2.4'))
    assert b.on_same_line?(OhlohScm::BranchNumber.new('1.3.6.3.2.99'))

    refute b.on_same_line?(OhlohScm::BranchNumber.new('1.4'))
    refute b.on_same_line?(OhlohScm::BranchNumber.new('1.1.2.1'))
    refute b.on_same_line?(OhlohScm::BranchNumber.new('1.2.2.1'))
    refute b.on_same_line?(OhlohScm::BranchNumber.new('1.3.2.1'))
    refute b.on_same_line?(OhlohScm::BranchNumber.new('1.3.4.1'))
    refute b.on_same_line?(OhlohScm::BranchNumber.new('1.3.6.1.2.1'))
    refute b.on_same_line?(OhlohScm::BranchNumber.new('1.3.6.4'))
    refute b.on_same_line?(OhlohScm::BranchNumber.new('1.3.6.3.4.1'))
    refute b.on_same_line?(OhlohScm::BranchNumber.new('1.3.6.3.2.2.2.1'))
    refute b.on_same_line?(OhlohScm::BranchNumber.new('1.3.6.3.2.99.2.1'))
  end

  # Crazy CVS inserts a zero before the last piece of a branch number
  it 'must test magic branch numbers' do
    assert OhlohScm::BranchNumber.new('1.1.2.1').on_same_line?(OhlohScm::BranchNumber.new('1.1.0.2'))
    assert OhlohScm::BranchNumber.new('1.1.2.1.2.1').on_same_line?(OhlohScm::BranchNumber.new('1.1.0.2'))

    assert OhlohScm::BranchNumber.new('1.1.0.2').on_same_line?(OhlohScm::BranchNumber.new('1.1'))
    refute OhlohScm::BranchNumber.new('1.1.0.2').on_same_line?(OhlohScm::BranchNumber.new('1.2'))
    assert OhlohScm::BranchNumber.new('1.1.0.2').on_same_line?(OhlohScm::BranchNumber.new('1.1.2.1'))

    assert OhlohScm::BranchNumber.new('1.1.0.4').on_same_line?(OhlohScm::BranchNumber.new('1.1'))
    refute OhlohScm::BranchNumber.new('1.1.0.4').on_same_line?(OhlohScm::BranchNumber.new('1.1.2.1'))
    refute OhlohScm::BranchNumber.new('1.1.0.4').on_same_line?(OhlohScm::BranchNumber.new('1.1.0.2'))
    assert OhlohScm::BranchNumber.new('1.1.0.4').on_same_line?(OhlohScm::BranchNumber.new('1.1.4.1'))
    refute OhlohScm::BranchNumber.new('1.1.0.4').on_same_line?(OhlohScm::BranchNumber.new('1.1.0.6'))
  end
end
