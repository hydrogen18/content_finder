# frozen_string_literal: true
require 'nokogiri'
require 'active_support/all'
require 'null_logger'

require 'content_finder/cli'

module ContentFinder

  module Log
    mattr_accessor :logger
    @@logger = NullLogger.new
    def log
      ::ContentFinder::Log.logger
    end
  end

  class LogarithmicThreshold
    def call(depth)
      0.001 + Math.log(1.0 + depth/7.0) 
    end
  end

  class TagCounter
    attr_reader :cache
    attr_reader :ignore_tags
    
    def initialize(options = {})
      @ignore_tags = options.fetch(:ignore_tags)
      @cache = {}
      reset
    end

    def reset
      @current = []
      self
    end 

    def length
      @current.length
    end

    def push(tag) 
      @sorted = false
      @current.push([tag, count_for(tag)])
      self
    end

    def count_for(node, parent = nil)
      value = @cache[node]      
      return value if value.present?

      value = 1.0 + ( 
      if node.comment?
        0.0
      elsif node.text?  
        if node.comment? || ignore_tags.include?(parent.try(:name))
          0.0
        else 
          node.text.strip.length
        end        
      else
        node.children.map do |child_node| 
          count_for(child_node, node)
        end.sum
      end)

      @cache[node] = value
    end

    def total
      @current.map { |x| x.fetch(1) }.sum.to_f
    end

    def sort!
      return if @sorted

      @current.sort_by!{ |x| x.fetch(1) }
      @sorted = true
    end

    def to_a
      sort!
      @current
    end

    def percentages
      sort!
      @current.map do |x|
        [x.fetch(0), x.fetch(1)/total]
      end
    end

    def spread
      return 0.0 if @current.empty?
      percentages.last.fetch(1) - percentages.first.fetch(1)
    end
  end

  class SelectionResult
    attr_reader :images
    attr_reader :hrefs
    def initialize
      @nodes = []
      @is_tree = []    
      @images = []
      @hrefs = []   
    end

    def push_tree(node)
      subtree = SelectionResult.new
      @is_tree.push(true)      

      node.children.each do |child_node|
        subtree.push(child_node)
        if child_node.name.downcase == 'img'
          subtree.images.push(node.to_html)
        elsif child_node.name.downcase == 'a'
          href = child_node.attribute('href')
          if href.present?
            subtree.hrefs.push(href)
          end 
        end
      end
      @nodes.push(subtree)      
    end

    def push_text(node)
      @is_tree.push(false)
      @nodes.push(node.to_str.strip)
    end      

    def push(node)
      if node.text?
        push_text(node)
      else
        push_tree(node)                
      end
    end

    def all_hrefs
      result = hrefs.dup
      @nodes.each_with_index do |node, idx|
        if @is_tree.fetch(idx)
          result += node.all_hrefs

        end
      end
      result
    end
    
    def to_str
      if !block_given?
        accum = []
        to_str do |x|
          accum.push(x)
        end 
        return accum.join('')
      end
      
      @nodes.each_with_index do |node, idx|
        if @is_tree.fetch(idx)
          node.to_str do |x|  
            yield(x)            
          end
        else
          yield(node) 
        end
      end
    end    
  end

  class HeuristicFinder
    include Log
    IGNORE_TAGS = ::Set.new(['head','script','style']).freeze

    attr_reader :recursion_spread_percent
    attr_reader :recursion_threshold_getter
    attr_reader :input    
    attr_reader :selected_html
    attr_reader :selected_result
    def initialize(input, options = {})
      @input = input
      @recursion_spread_percent = options.fetch(:recursion_spread_percent)/100.0
      @recursion_threshold_getter = options.fetch(:recursion_threshold_getter)
      @depth = 0
    end

    def threshold
      recursion_threshold_getter.call(@depth)
    end

    def find!      
      doc = ::Nokogiri::HTML::Document.parse(input) do |config|
        config.options = Nokogiri::XML::ParseOptions::NONET
      end

      selection = doc.root
      counts = TagCounter.new(ignore_tags: IGNORE_TAGS)
      #TODO check doc.errors
      loop do
        counts.reset      
        selection.children.each do |node|
          next if IGNORE_TAGS.include?(node.name)
          counts.push(node)
        end
 
        log.info "#{counts.length} candidates, spread of #{counts.spread}"
        if counts.length == 1 || counts.spread > recursion_spread_percent           
          largest = counts.to_a.last
          largest_pct = largest.fetch(1)/counts.total

          if largest_pct > threshold
            log.info "Candidate passes #{largest_pct} > #{threshold}"
            @depth += 1
            selection = largest.fetch(0)
            next
          else
            log.info "Candidate fails #{largest_pct} > #{threshold}"
          end 
        else 
          log.info "Spread test failed"        
        end  
        break selection
      end

      @selected_result = SelectionResult.new
      @selected_result.push(selection)
      
      @selected_html = selection.to_html
    end

    def selected_text
      @selected_result.to_str
    end

    def pretty_selected_text
      if !block_given?
        accum = []
        pretty_selected_text do |x|
          accum.push(x)
        end 
        return accum.join('')
      end

      yield('<!DOCTYPE html><html>')
      yield('<body>')
      @selected_result.to_str do |x|
        yield('<p>')
        yield(x)
        yield('</p>')
      end 
      yield('</body>')
      yield('</html>')
    end
 
  end

  class HeuristicFinderFactory
    attr_reader :recursion_spread_percent
    attr_reader :recursion_threshold_getter

    def initialize(recursion_spread_percent, recursion_threshold_getter)
      @recursion_spread_percent = recursion_spread_percent
      @recursion_threshold_getter = recursion_threshold_getter
    end

    def build(input)
      HeuristicFinder.new(input,
        recursion_spread_percent: recursion_spread_percent,
        recursion_threshold_getter: recursion_threshold_getter)
    end
  end
  mattr_accessor :default_factory
  @@default_factory = HeuristicFinderFactory.new(75.0,
    ::ContentFinder::LogarithmicThreshold.new)
  def self.heuristic_finder(input)
    default_factory.build(input)
  end

end