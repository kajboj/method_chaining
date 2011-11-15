module MethodChaining
  DEFAULT_CHAIN_BREAKER = lambda do |o|
    o.nil?
  end

  DEFAULT_RETURN_VALUE = nil

  # Note that klasses are constantized at the end of this module after all the classes are defined.
  CHAIN_METHODS = {
    :begin => {:name => "__b__",     :klasses => %w(Chain)},
    :end   => {:name => "__e__",     :klasses => %w(Wrapper Swallower)},
    :let   => {:name => "___let___", :klasses => %w(Wrapper)},
  }
  
  def self.config(options)
    options.each_pair do |k, v|
      alias_chain_method(CHAIN_METHODS[k][:klasses], k, v)
    end
  end

  def self.alias_chain_method(klasses, method_symbol, new_method_name)
    klasses.each do |klass| 
      klass.class_eval do
        old_method_name = CHAIN_METHODS[method_symbol][:name]
        if old_method_name != new_method_name
          alias_method new_method_name, old_method_name
          remove_method old_method_name
        end
      end
    end
    CHAIN_METHODS[method_symbol][:name] = new_method_name
  end

  class Wrapper
    instance_methods.each do |m|
      undef_method m unless m.to_s =~ /method_missing|respond_to?|^__/
    end

    def initialize(o, def_ret, tc)
      @o, @tc, @def_ret = o, (tc || DEFAULT_CHAIN_BREAKER), (def_ret || DEFAULT_RETURN_VALUE)
    end

    def method_missing(method, *args, &blk)
      r = @o.send(method, *args, &blk)
      @tc.call(r) ? Swallower.new(@def_ret) : Wrapper.new(r, @def_ret, @tc)
    end

    eval <<-END_EVAL
      def #{CHAIN_METHODS[:let][:name]}
        Wrapper.new(yield(@o), @def_ret, @tc)
      end

      def #{CHAIN_METHODS[:end][:name]}; @o end
    END_EVAL
  end

  class Swallower
    instance_methods.each do |m|
      undef_method m unless m.to_s =~ /method_missing|respond_to?|^__/
    end

    def initialize(ret)
      @ret = ret
    end

    def method_missing(method, *args, &blk)
      self
    end

    eval <<-END_EVAL
      def #{CHAIN_METHODS[:end][:name]}; @ret end
    END_EVAL
  end

  module Chain
    eval <<-END_EVAL
      def #{CHAIN_METHODS[:begin][:name]}(return_val = nil, &chain_breaker)
        MethodChaining::Wrapper.new(self, return_val, chain_breaker)
      end
    END_EVAL
  end

  CHAIN_METHODS.values.each do |method_info|
    method_info[:klasses] = method_info[:klasses].collect do |s|
      self.const_get(s)
    end
  end
end
