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
        @blacklist_pattern ||= /\b(#{blacklist.map {|a| "(?:#{a})"}.join('|')})\b/i
      end

      def whitelist_pattern
        @whitelist_pattern ||= /\b(#{whitelist.map {|a| "(?:#{a})"}.join('|')})\b/
      end

      def profane?(text)
        return false unless text.to_s.size >= 3
        text.split.each do |piece|
          next if piece =~ whitelist_pattern
          return true if piece =~ blacklist_pattern
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
        blacklist.each do |foul|
          words << foul if text =~ /\b#{foul}\b/i && !whitelist.include?(foul)
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

    end
  end
end
