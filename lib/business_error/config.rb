# frozen_string_literal: true

module BusinessError
  class Config
    cattr_accessor :formats, default: { }
    cattr_accessor :default_format, default: nil
    cattr_accessor :default_http_status, default: 200
  end
end
