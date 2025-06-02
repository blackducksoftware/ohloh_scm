# frozen_string_literal: true

module OhlohScm
  class BranchNumber
    def initialize(branch_number)
      @num = branch_number.split('.').collect(&:to_i)
      # Accomodate CVS magic branch numbers by swapping the magic zero
      # That is, 1.1.0.2 => 1.1.2.0
      @num[-1], @num[-2] = @num[-2], @num[-1] if (@num.size > 2) && @num[-2].zero?
    end

    # Returns true if <branch_number> is an ancestor of this object,
    # or if this object follows <branch_number> on the same line.
    def on_same_line?(branch_number)
      b = branch_number.to_a

      # b has been branched more times than this object.
      return false if b.size > @num.size
      if b.size == @num.size
        # b and a have the same number of branch events.
        # If either one inherits from the other then they
        # are on the same line.
        return inherits_from?(branch_number) || branch_number.inherits_from?(self)
      end

      # b has not been branched as often as this object.
      # That's OK if b is an ancestor of this object.
      inherits_from?(branch_number) if b.size < @num.size
    end

    def to_a
      @num
    end

    protected

    # Returns true if <branch_number> is an ancestor of this object.
    # Also returns true if <branch_number> is the same as this object.
    # rubocop:disable Metrics/AbcSize
    def inherits_from?(branch_number)
      b = branch_number.to_a

      return false if b.size > @num.size

      return false if b.size == 2 && descendant?(b)

      unless b.size == 2
        0.upto(b.size - 2) do |i|
          return false if b[i] != @num[i]
        end
        return false if b[-1] > @num[b.size - 1]
      end
      true
    end
    # rubocop:enable Metrics/AbcSize

    private

    def descendant?(branch_number)
      true if branch_number[0] > @num[0] ||
              ((branch_number[0] == @num[0]) && (branch_number[1] > @num[1]))
    end
  end
end
