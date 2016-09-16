module Obscenity
  class Base
    class << self

      def blacklist
        @blacklist ||= set_list_content(Obscenity.config.blacklist) - whitelist
      end

      def blacklist=(value)
        @blacklist = value == :default ? set_list_content(Obscenity::Config.new.blacklist) : value
        @blacklist_pattern = nil
      end

      def whitelist
        @whitelist ||= set_list_content(Obscenity.config.whitelist)
      end

      def whitelist=(value)
        @whitelist = value == :default ? set_list_content(Obscenity::Config.new.whitelist) : value
        @whitelist_pattern = nil
      end

      def blacklist_pattern
        @blacklist_pattern ||= /(\b|\W|\A)(#{blacklist.map {|a| "(?:#{Regexp.escape(a)})"}.join('|')})(\b|\W|\z)/i
      end

      def whitelist_pattern
        @whitelist_pattern ||= /(\b|\W|\A)(#{whitelist.map {|a| "(?:#{Regexp.escape(a)})"}.join('|')})(\b|\W|\z)/
      end

      def profane?(text)
        return false unless text.to_s.size >= 3
        text.split.each do |piece|
          return true if offensive_word? piece
        end
        false
      end

      def sanitize(text)
        return(text) unless text.to_s.size >= 3
        blacklist.each do |foul|
          text.gsub!(/\b#{foul}\b/i, replace(foul)) unless whitelist.include?(foul)
        end
        @scoped_replacement = nil
        text
      end

      def replacement(chars)
        @scoped_replacement = chars
        self
      end

      def offensive(text)
        words = []
        return(words) unless text.to_s.size >= 3
        text.split.each do |piece|
          words << piece if offensive_word? piece
        end
        words.uniq
      end

      def replace(word)
        content = @scoped_replacement || Obscenity.config.replacement
        case content
        when :vowels then word.gsub(/[aeiou]/i, '*')
        when :stars  then '*' * word.size
        when :nonconsonants then word.gsub(/[^bcdfghjklmnpqrstvwxyz]/i, '*')
        when :default, :garbled then '$@!#%'
        else content
        end
      end

      private
      def set_list_content(list)
        case list
        when Array then list
        when String, Pathname then YAML.load_file( list.to_s )
        else []
        end
      end

      def offensive_word?(word)
        return false unless word.size >= 3
        return false if !whitelist.empty? && word =~ whitelist_pattern
        return true if word =~ blacklist_pattern
        false
      end
    end
  end
end
