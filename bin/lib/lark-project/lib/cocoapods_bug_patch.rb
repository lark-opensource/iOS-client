module Pod
  module UserInterface
    module ErrorReport
      # fix forced_encoding frozen string error
      old = method(:report)
      define_singleton_method(:report) do |exception|
        if (msg = exception.message).frozen?
          msg = msg.dup
          exception.define_singleton_method(:message) { msg }
        end
        old.(exception)
      end
    end
  end
end
