module ContentFinder
  module CLI
    def self.run!
      input = 
      if ARGV[0].present?
        File.open(ARGV[0], 'r')
      else 
        STDIN
      end

      log = ENV['CF_LOGGER']

      if log.present?
        log_instance = 
        if log.downcase == 'stderr'
          ::Logger.new(STDERR, )
        else 
          ::Logger.new(File.open(log))
        end
        
        log_lvl = ENV['CF_LOG_LEVEL']
        log_instance.level =  
        if log_lvl.present?
          ::Logger.const_get(log_lvl.upcase)
        else
          ::Logger::INFO
        end

        ::ContentFinder::Log.logger = log_instance
      end

      cf = ::ContentFinder.heuristic_finder(input)
      cf.find!

      if 'html' == ENV.fetch('CF_OUTPUT', 'html').downcase
        STDOUT.write(cf.selected_html)
      else 
        STDOUT.write(cf.selected_text)
      end
      STDOUT.close

      input.close
    end
  end
end