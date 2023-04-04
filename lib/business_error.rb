require 'business_error/version'
require 'business_error/error'
require 'business_error/config'

module BusinessError
  cattr_accessor(:defs_tree) { { } }
  attr_accessor :defs

  def mattr_reader name, message = '', code = _get_code, http: _get_http, group: _get_group
    message = name.to_s.humanize if message.blank?

    define_singleton_method(name) { Error.new(name, message, code, http) }
    # TODO raise Error, name, message, code
    define_singleton_method("#{name}!") { raise Error.new(name, message, code, http) }

    defs_tree[self.name] ||= { }
    (defs_tree[self.name][group] ||= [ ]) << { name: name, msg: message, code: code, http: http }
    ((@defs ||= { })[group] ||= []) << name
  end

  alias_method :define, :mattr_reader

  def group group_name = :private, code_start_at = @code, http: _get_http, &block
    @group_name, @code, @http, group_name, code_start_at, http = group_name, code_start_at, http, @group_name, @code, @http
    instance_eval(&block)
    @group_name, @code, @http = group_name, code_start_at, http
  end

  def _get_group
    @group_name || :public
  end

  def _get_code
    raise ArgumentError, 'Should give a code to define your business error' if (code = @code).nil?
    @code = @code < 0 ? (code - 1) : (code + 1)
    code
  end

  def code_start_at code
    @code = code
  end

  def http status_code
    @http_status = status_code
  end

  def _get_http
    @http_status || Config.default_http_status
  end

  def define_px name, message = '', code = _get_code, http: _get_http
    group_name = name.to_s.split('_').first.to_sym
    group group_name do
      mattr_reader name, message, code, http: http, group: group_name
    end
  end

  def inherited(subclass)
    defs_tree[self.name]&.keys&.each do |group|
      defs_tree[self.name][group].each do |e|
        # TODO: how to undef class method?
        subclass.define_singleton_method(e[:name]) { raise NoMethodError }
        subclass.define_singleton_method(e[:name].to_s + '!') { raise NoMethodError }
      end
    end
  end

  def print
    puts defs_tree[self.name].stringify_keys.to_yaml.gsub(' :', ' ')
  end

  def all
    puts defs_tree.stringify_keys.to_yaml.gsub(' :', ' ')
  end
end
