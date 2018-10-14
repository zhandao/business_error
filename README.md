# BusinessError

Business Error Management by using OOP

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'business_error'
```

And then execute:

    $ bundle

## Usage

### 1. Config file

initializer `business_error.rb`

```ruby
BusinessError::Config.tap do |config|
  config.default_http_status = 200
end
```

### 2. About `BusinessError::Error`

```ruby
# new an error
e = BusinessError::Error.new(
  name = :invalid_token,
  msg = 'your token is invalid',
  code = 1001,
  http_status = 400 # it is optional
)

e.info # => { code: 1001, msg: '...', http: 400 }
e.message # => "{ code: 1001, msg: '...', http: 400 }"
```

### 3. Define Error

#### 3.a Recommended Practice

1. Create new directories `_docs/error` in the `/app` directory.

2. Add `config.eager_load_paths << "#{Rails.root}/app/_docs"` to your `application.rb`.

3. Create a base error class, like `api.rb`:
    ```ruby
    # app/_docs/error/api.rb
    class Error::Api
      extend BusinessError
   
      define :invalid_token, 'Your token is invalid', 1001
    end
    ```
    The class method `define` will define an `BusinessError::Error` by the given
    name, msg and code.
    
4. Now you can create more error class inherited from `Error::Api`:
    ```ruby
    class Error::Foo < Error::Api
      define :bar, 'bar', 2002
    end
    ```
    
And then, try it in your console!

```ruby
Error::Api.invalid_token # => an instance of BusinessError::Error initialized by the given params
Error::Foo.invalid_token # Yes, this error comes from inheritance!
Error::Foo.bar           # This error is defined by itself

# How to raise an error? -- Bang with the same name
Error::Api.invalid_token! # => will raise an BusinessError::Error with defined message

# Methods for getting all of error definitions
#   Get the error class's error definitions
Error::Api.print # It will print a YAML for showing it's groups and their error definitions
#   Get this error class AND it's ancestors and descendants' error definition
Error::Api.tree  # YAML also
```

#### 3.b Preventing error definition inheritance via grouping them

```ruby
# Error::Api
group :group_name do 
  define :foo, 'foo', 1
  define :bar, 'bar', 2
end
# Then
Error::Api.foo # ok
Error::Foo.foo # NoMethodError!

# method signature
group group_name = :private, code_start_at = nil, http: 200, &block
```

#### 3.c Using the same name to define?

NOT supported currently. It leads to method override,
the last definition will leave.

#### 3.x Skills

1. Use `mattr_reader` instead of `define` (alias) IF you're using Rubymine.

    It makes Rubymine auto completion more perfect.
    
2. Use `define_px` (define an error and group it into the group named that the prefix of error name)

    ```ruby
    define_px :create_failed, '', -1
    # the same as below:
    group :create do
      define :create_failed, '', -1
    end
    # or
    define :create_failed, '', -1, group: :create # or call `mattr_reader`
    ```
    
3. Passing blank message:

    ```ruby
    define :create_failed, '', -1
    # then, the message of this error will be:
    :create_failed.to_s.humanize
    ```
    
4. `code_start_at`

    ```
    code_start_at 0
    define ... # code is 0
    define ... # code is 1
    define ... # code is 2
 
    code_start_at -1
    define ... # code is -1
    define ... # code is -2
    define ... # code is -3
    ```
    
5. `http`
    
    ```
    http 500
    define ... # http is 500
    define ... # http is 500
    
    http :forbidden
    define ... # http is :forbidden (403)
    ```

### 4. Raise Error

Just: error_name + bang!

```ruby
Error::Api.invalid_token! # => BusinessError::Error! with invalid_token's message
```

#### 4.a `with!` for error info customization

```ruby
Error::Api.invalid_token.with!(hello: 'world')
# it will raise an invalid_token error with info:
#   { code: 1001, msg: '...', http: 400, hello: 'world' }
```

#### 4.b `format!` in order to be compatible with different info format requirements

error.info have a hash format defaults to:  
`{ code: @code, msg: @msg, http: @http_status }`

```ruby
# Suppose we need a format called "old"
# initializer
config.formats[:old] = %i[ status message http ]

# If:
Error::Api.invalid_token.format!(:old)
# it will raise an invalid_token error with info:
#   { only: { status: 1001, message: '...', http: 400 } }

Error::Api.invalid_token.format!(:old, hello: 'world') # it's ok
```

the key `only` is for [`output`]()

More complex formatting is to be done:
```ruby
config.formats[:old] = { format: {
  status: 0,
  foo: {
    bar: 'default value',
    msg: 'success'
  },
  http: 200
}, code: [:status], msg: [:foo, :msg], http: :http }
```

`format!` has an alias `render!`

### 5. Rescue Error and render response by [`OutPut`]()

Just do:
```ruby
output Error::Api.invalid_token
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/business_error. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the BusinessError project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/business_error/blob/master/CODE_OF_CONDUCT.md).
