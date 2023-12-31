# frozen_string_literal: true

module Lark::Misc
  # true, number ~0, string begin with ~0, yY, tT will return true.
  # other type will return nil
  # @return [Boolean, nil]
  def self.true?(value)
    case value
    when nil then return nil
    when String
      return nil if value.empty?

      return /^[1-9yYtT]/.match? value
    when Numeric then return value != 0
    when true then return true
    when false then return false
    end
    nil
  end

  # try require and return false if not exist
  def self.require?(path)
    require path
    true
  rescue LoadError
    false
  end
end
