require 'business_error/config'

module BusinessError
  class Error < StandardError
    attr_accessor :name, :msg, :code, :http_status, :format

    def initialize(name, msg, code, http_status = Config.default_http_status, format = Config.default_format)
      msg = name.to_s.humanize if msg.blank?
      @name, @msg, @code, @http_status = name, msg, code, http_status
      self.format = format
    end

    def info
      @info ||= { code: @code, msg: @msg, http: @http_status }
    end

    def throw!
      format ? format!(format) : (raise self)
    end

    def format!(template, **addition_content)
      content = Config.formats[template].each_with_index.map { |k, i| [k, info.values[i]] }.to_h
      @info = { only: content.merge(addition_content) }
      raise self
    end

    alias render! format!

    def with!(**addition_content)
      info.merge!(data: addition_content)
      raise self
    end

    def message; info.to_s end
  end
end
