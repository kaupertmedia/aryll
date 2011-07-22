module Kauperts
  class LinkChecker

    attr_reader :object

    def initialize(object)
      object.respond_to?(:url) ? @object = object : raise(ArgumentError.new("object doesn't respond to url"))
    end

  end
end
