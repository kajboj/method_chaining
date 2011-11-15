require 'method_chaining'

describe "chaining" do
  before(:each) do
    @o = Mock.new
  end

  describe "with no params" do
    it "should work with good chain" do
      @o._begin.s.s.s.s.s.m._let do |x|
        "(#{x})" 
      end.size.to_s._end.should == "6"
    end

    it "should return nil with broken chain" do
      @o._begin.s.s.nil_method.s.s.m._end.should be_nil
    end

    it "should return provided default value" do
      @o._begin(:broken_chain).s.s.nil_method.s.s.m._end.should == :broken_chain
    end

    it "should return provided default value when custom termination condition occurs" do
      @o._begin(:broken_chain) {|o| o == 'terminate'}.s.s.ct.s.s.m._end.should == :broken_chain
    end
  end

  describe "with params" do
    it "should work with good chain" do
      @o._begin.t(true).t(false).e("hello")._end.should == 'hello'
    end  

    it "should return nil with broken chain" do
      @o._begin.t(true).t(false).nil_method.e("hello")._end.should be_nil
    end  
  end

  MethodChaining.config(
    :begin => :_begin,
    :end   => :_end,
    :let   => :_let
  )

  class Object
    include MethodChaining::Chain
  end

  class Mock
    def nil_method; nil end
    def s; self end
    def m; "mock" end
    def ct; "terminate" end
    def e(s); s end
    def t(new)
      new ? Mock.new : self
    end
  end
end
