module BusinessError
  class Config
    cattr_accessor :formats do
      { }
    end

    cattr_accessor :default_http_status do
      200
    end
  end
end
