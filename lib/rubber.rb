# setup load paths
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'rubber'))

vendor_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'vendor'))
Dir.glob(File.join(vendor_path, '*')).each do |vendored_dir|
  puts "VENDOR loading #{vendored_dir}"
  $LOAD_PATH.unshift(File.join(vendored_dir, 'lib'))
end

require 'rubygems'
require 'active_support/inflector'
require 'johnson'

require 'rubber/runtime'


module Rubber
    
  def self.included(base)
    puts "#{base} is now wearing Rubber"
    augment_with_methods_from_javascript(base)
  end
  
  def self.augment_with_methods_from_javascript(base)
    puts "doing magic for #{base}"
    base_name = base.name.underscore + ".js"
    js_file_path = File.join(global_js_base_path, base_name)
    puts "loading from #{js_file_path}"
    
    def base.js_file
      @js_file
    end
    
    def base.js_file=(file)
      @js_file=file
    end
    
    def base.singleton_instance_var
      self.name.demodulize.underscore
    end
    
    # this is where the magic happens
    def base.load_js_methods
      class_name = self.name.demodulize
      # TODO: DRY this up
      singleton_instance_var = self.name.demodulize.underscore      
      begin
        # Load and evaluate the associated javascript
        js_contents = IO.read js_file
        runtime = Rubber::Runtime::GLOBAL
        runtime.evaluate(js_contents)
        
        puts "var #{singleton_instance_var} = new #{class_name}()"
        runtime.evaluate("var #{singleton_instance_var} = new #{class_name}()")
        result = runtime.evaluate("listmembers(#{singleton_instance_var})")
        puts "#{class_name} members: #{result.to_a.join(',')}"
        
        # puts runtime.evaluate("typeof test['myvar'] == 'function' ? test.myvar() : test.myvar");
        # puts runtime.evaluate("typeof test['myfunc'] == 'function' ? test.myfunc() : test.myfunc");
      rescue Errno::ENOENT => e
        puts "WARNING: #{e}"
      rescue Johnson::Error => je
        puts "WARNING: JS environment does not contain #{class_name}: #{je}"
      end
    end
    
    base.js_file=js_file_path
    
    base.load_js_methods
  end
  
  def self.global_js_base_path
    @js_base_path ||= 'public'
  end
  
  def self.global_js_base_path=(path)
    @js_base_path = path
  end
  
  # makes the library detectable
  def wearing_rubber
    true
  end
  
  # the Javascript file that should correspond to this one
  def js_file
    self.class.js_file
  end
  
  def method_missing(name, *args, &block)
    begin
      puts "method missing: #{name}"
      script = "#{self.class.singleton_instance_var}.#{name}()"
      puts script
      
      return Rubber::Runtime::GLOBAL.evaluate(script)
    rescue
      super(name, args, block)
    end
  end
  
end