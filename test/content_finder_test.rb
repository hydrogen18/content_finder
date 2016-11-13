require 'minitest/autorun'
require 'pry'
require 'content_finder'

class ContentFinderTest < MiniTest::Test
  def data_files
    Dir['test/data/*']
  end
  def test_content_finder
    data_files.to_a.shuffle.each do |filename|
      File.open(filename, 'r') do |fin|
        
        finder = ::ContentFinder.heuristic_finder(fin)        
        finder.find!
        
        File.open('/home/ericu/tmp.html','w') do |fout|
          fout.write(finder.selected_html)
        end        
        
      end
    end
  end
end 