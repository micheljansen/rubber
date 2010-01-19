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
    augment_with_methods_from_javascript(base)
  end
  
  def self.augment_with_methods_from_javascript(base)
    base_name = base.name.underscore + ".js"
    js_file_path = File.join(global_js_base_path, base_name)
    
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
    def base.load_js_delegate
      class_name = self.name.demodulize
      # TODO: DRY this up
      singleton_instance_var = self.name.demodulize.underscore      
      begin
        # Load and evaluate the associated javascript
        js_contents = IO.read js_file
        runtime = Rubber::Runtime::GLOBAL
        runtime.evaluate(js_contents)
        
        # puts "var #{singleton_instance_var} = new #{class_name}()"
        script = "var #{singleton_instance_var} = new #{class_name}(); #{singleton_instance_var}"
        # runtime.evaluate(class_name).apply_wrappers(self)
        @js_delegate = js_delegate = runtime.evaluate(script)
        return js_delegate
      rescue Errno::ENOENT => e
        puts "WARNING: #{e}"
      rescue Johnson::Error => je
        puts "WARNING: JS environment does not contain #{class_name}: #{je}"
      end
    end
    
    def base.js_delegate
      @js_delegate ||= load_js_delegate
    end
    
    base.js_file=js_file_path
    
    base.load_js_delegate
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
      begin
        # try the delegate first
        self.class.js_delegate.method_missing(name, args, block)
      rescue
        # maybe it's a proparty
        self.class.js_delegate.send(name)
      end
    rescue => e
      puts "DEBUG: #{e}"
      # revert to default
      super.method_missing(name, args, block)
    end
  end
end