require 'i18n/backend/base'

module I18n
  module Backend
    class SequelBitemporal
      autoload :Missing,     'i18n/backend/sequel_bitemporal/missing'
      autoload :StoreProcs,  'i18n/backend/sequel_bitemporal/store_procs'
      autoload :Translation, 'i18n/backend/sequel_bitemporal/translation'

      module Implementation
        include Base, Flatten

        def available_locales
          begin
            Translation.available_locales
          rescue ::Sequel::Error
            []
          end
        end

        def store_translations(locale, data, options = {})
          escape = options.fetch(:escape, true)
          flatten_translations(locale, data, escape, false).each do |key, value|
            # Invalidate all keys matching current one:
            # key = foo.bar invalidates foo, foo.bar and foo.bar.*
            Translation.locale(locale).lookup(expand_keys(key)).destroy
            
            # Find existing master for locale/key or create a new one
            translation = Translation.locale(locale).lookup_exactly(expand_keys(key)).limit(1).all.first ||
                          Translation.new(:locale => locale.to_s, :key => key.to_s)
            translation.attributes = {:value => value}
            translation.save
          end
        end

      protected

        def lookup(locale, key, scope = [], options = {})
          key = normalize_flat_keys(locale, key, scope, options[:separator])
          result = Translation.locale(locale).lookup(key).all

          if result.empty?
            nil
          elsif result.first.key == key
            result.first.value
          else
            chop_range = (key.size + FLATTEN_SEPARATOR.size)..-1
            result = result.inject({}) do |hash, r|
              hash[r.key.slice(chop_range)] = r.value
              hash
            end
            result.deep_symbolize_keys
          end
        end

        # For a key :'foo.bar.baz' return ['foo', 'foo.bar', 'foo.bar.baz']
        def expand_keys(key)
          key.to_s.split(FLATTEN_SEPARATOR).inject([]) do |keys, key|
            keys << [keys.last, key].compact.join(FLATTEN_SEPARATOR)
          end
        end
      end

      include Implementation
    end
  end
end
