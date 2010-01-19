require 'johnson/runtime'

module Rubber
  module Runtime
    global_js_path = IO.read(File.join(File.dirname(__FILE__), 'globals.js'))
    GLOBAL = Johnson::Runtime.new
    GLOBAL.evaluate(global_js_path)
  end
end