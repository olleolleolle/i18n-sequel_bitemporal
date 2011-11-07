# This module is intended to be mixed into the Sequel backend to allow
# storing Ruby Procs as translation values in the database.
#
#   I18n.backend = I18n::Backend::Sequel.new
#   I18n::Backend::Sequel::Translation.send(:include, I18n::Backend::Sequel::StoreProcs)
#
# The StoreProcs module requires the ParseTree and ruby2ruby gems and therefor
# was extracted from the original backend.
#
# ParseTree is not compatible with Ruby 1.9.

begin
  require 'ruby2ruby'
  require 'parse_tree'
  require 'parse_tree_extensions'
rescue LoadError => e
  puts "can't use StoreProcs because: #{e.message}"
end

module I18n
  module Backend
    class SequelBitemporal
      module StoreProcs
        def value=(v)
          case v
          when Proc
            super(v.to_ruby)
            self.is_proc = true
          else
            super(v)
          end
        end

        Translation.send(:include, self) if method(:to_s).respond_to?(:to_ruby)
      end
    end
  end
end

