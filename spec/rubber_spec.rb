require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'rubber'

describe "Rubber" do
  
  before(:each) do
    Rubber.global_js_base_path = File.expand_path(File.join(File.dirname(__FILE__), 'js'))
    
    class Test
      include Rubber
    end
  end
  
  it 'should provide hints of inclusion' do
    Test.new.should respond_to :wearing_rubber
  end  
  
  it 'should know its equivalent javascript filename' do    
    Test.new.should respond_to :js_file
    Test.js_file.should == Test.new.js_file
  end
  
  it 'should be possible to change the global base path' do
    original_path = Regexp.new(File.expand_path(File.join(File.dirname(__FILE__), 'js')))
    Test.js_file.should =~ original_path
    Rubber.global_js_base_path = 'public/js'
    Test.js_file.should =~ original_path
    
    class OtherTest
      include Rubber
    end
    
    OtherTest.js_file.should =~ /^public\/js/
  end
  
  it 'should include functions from javascript' do
    Test.new.hello().should == "world"
  end
  
  it 'should include variables from javascript' do
    Test.new.foo.should == "bar"
  end

end