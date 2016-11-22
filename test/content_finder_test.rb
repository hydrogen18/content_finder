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
=begin          
          fout.write('<div>')
          fout.write('<ul>')
          finder.selected_result.all_hrefs.each do |href|
            fout.write('<li>')
            fout.write('<a href="')
            fout.write(href)
            fout.write('">')
            fout.write(href)
            fout.write('</a>')
            fout.write('</li>')
          end
          fout.write('</ul>')
          fout.write('</div>')
          fout.write(finder.selected_html)
=end
          fout.write(finder.selected_text)                    
        end                
      end
    end
  end
end 