# frozen_string_literal: true
require 'request_store'

require 'business_error/version'
require 'business_error/error'
require 'business_error/config'

module BusinessError
  cattr_accessor(:defs_tree) { { } }
  attr_accessor :defs

  def mattr_reader name,
                   message = name.to_s.humanize,
                   code = _get_code,
                   http: _get_http,
                   group: _get_group,
                   format: @format
    define_singleton_method(name) do |locale = _get_locale|
      msg = message.is_a?(Hash) ? (message[locale] || message[:en]) : message
      Error.new(name, msg, code, http, format)
    end

    define_singleton_method("#{name}!") { send(name).throw! }

    defs_tree[self.name] ||= { }
    (defs_tree[self.name][group] ||= [ ]) << { name: name, msg: message, code: code, http: http }
    ((@defs ||= { })[group] ||= []) << name
  end

  alias_method :define, :mattr_reader

  def group group_name = :private, code_start_at = @code, http: _get_http, format: @format, &block
    @group_name, @code, @http, @format, group_name, code_start_at, http, format =
        group_name, code_start_at, http, format, @group_name, @code, @http, @format
    instance_eval(&block)
    @group_name, @code, @http, @format = group_name, code_start_at, http, format
  end

  def code_start_at code
    @code = code
  end

  def http status_code
    @http_status = status_code
  end

  def format template
    @format = template
  end

  def define_px name, message = '', code = _get_code, http: _get_http
    group_name = name.to_s.split('_').first.to_sym
    group group_name do
      mattr_reader name, message, code, http: http, group: group_name
    end
  end

  def inherited(subclass)
    defs_tree[self.name]&.keys&.each do |group|
      defs_tree[self.name][group].each do |name:, **_|
        # TODO: how to undef class method?
        subclass.define_singleton_method(name) { raise NoMethodError }
        subclass.define_singleton_method(name.to_s + '!') { raise NoMethodError }
      end
    end
  end

  def print
    puts defs_tree[self.name].stringify_keys.to_yaml.gsub(' :', ' ')
  end

  def all
    puts defs_tree.stringify_keys.to_yaml.gsub(' :', ' ')
  end

  # ===

  def _get_group
    @group_name || :public
  end

  def _get_code
    raise ArgumentError, 'Should give a code to define your business error' if (code = @code).nil?
    @code = @code < 0 ? (code - 1) : (code + 1)
    code
  end

  def _get_http
    @http_status || Config.default_http_status
  end

  def _get_locale
    RequestStore.store[:err_locale] ||= 'en'
  end
end
