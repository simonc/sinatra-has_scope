require 'sinatra/base'

module Sinatra
  module HasScope
    TRUE_VALUES = ["true", true, "1", 1]

    ALLOWED_TYPES = {
      :array    => [ Array ],
      :hash     => [ Hash ],
      :boolean  => [ Object ],
      :default  => [ String, Numeric ]
    }

    attr_accessor :scopes_configuration

    # Detects params from url and apply as scopes to your classes.
    #
    # == Options
    #
    # * <tt>:type</tt> - Checks the type of the parameter sent. If set to :boolean
    # it just calls the named scope, without any argument. By default,
    # it does not allow hashes or arrays to be given, except if type
    # :hash or :array are set.
    #
    # * <tt>:as</tt> - The key in the params hash expected to find the scope.
    # Defaults to the scope name.
    #
    # * <tt>:using</tt> - If type is a hash, you can provide :using to convert the hash to
    # a named scope call with several arguments.
    #
    # * <tt>:if</tt> - Specifies a method, proc or string to call to determine
    # if the scope should apply
    #
    # * <tt>:unless</tt> - Specifies a method, proc or string to call to determine
    # if the scope should NOT apply.
    #
    # * <tt>:default</tt> - Default value for the scope. Whenever supplied the scope
    # is always called.
    #
    # * <tt>:allow_blank</tt> - Blank values are not sent to scopes by default. Set to true to overwrite.
    #
    def has_scope(scope_group, *scopes)
      options = scopes.extract_options!
      options.symbolize_keys!
      options.assert_valid_keys(:type, :if, :unless, :default, :as, :using, :allow_blank)

      if options.key?(:using)
        if options.key?(:type) && options[:type] != :hash
          raise "You cannot use :using with another :type different than :hash"
        else
          options[:type] = :hash
        end

        options[:using] = [*options[:using]]
      end

      self.scopes_configuration ||= {}
      self.scopes_configuration[scope_group] ||= {}

      scopes.each do |scope|
        self.scopes_configuration[scope_group][scope] ||= {
          :as => scope,
          :type => :default
        }
        self.scopes_configuration[scope_group][scope].merge!(options)
      end
    end

    # Receives an object where scopes will be applied to.
    #
    # has_scope :graduation, :featured, :type => true
    # has_scope :graduation, :by_degree
    #
    # get '/graduations' do
    #   @graduations = apply_scopes(:graduation, Graduation, params).all
    # end
    #
    def apply_scopes(scope_group, target, hash)
      return target unless scopes_configuration

      if self.scopes_configuration.key?(scope_group)
        self.scopes_configuration[scope_group].each do |scope, options|
          key = options[:as].to_s

          if hash.key?(key)
            value, call_scope = hash[key], true
          elsif options.key?(:default)
            value, call_scope = options[:default], true
            value = value.call(self) if value.is_a?(Proc)
          end

          value = parse_value(options[:type], key, value)

          if call_scope && (value.present? || options[:allow_blank])
            target = call_scope_by_type(options[:type], scope, target, value, options)
          end
        end
      end

      target
    end

    # Set the real value for the current scope if type check.
    def parse_value(type, key, value) #:nodoc:
      if type == :boolean
        TRUE_VALUES.include?(value)
      elsif value && ALLOWED_TYPES[type].none?{ |klass| value.is_a?(klass) }
        raise "Expected type :#{type} in params[:#{key}], got #{value.class}"
      else
        value
      end
    end

    # Call the scope taking into account its type.
    def call_scope_by_type(type, scope, target, value, options) #:nodoc:
      if type == :boolean
        target.send(scope)
      elsif value && options.key?(:using)
        value = value.values_at(*options[:using])
        target.send(scope, *value)
      else
        target.send(scope, value)
      end
    end

    # Evaluates the scope options :if or :unless. Returns true if the proc
    # method, or string evals to the expected value.
    def applicable?(string_proc_or_symbol, expected) #:nodoc:
      case string_proc_or_symbol
        when String
          eval(string_proc_or_symbol) == expected
        when Proc
          string_proc_or_symbol.call(self) == expected
        when Symbol
          send(string_proc_or_symbol) == expected
        else
          true
      end
    end
  end

  register HasScope
end
