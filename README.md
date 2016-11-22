This is a ruby gem that uses heuristics to try and find the content in a given web page's HTML.

From ruby code, you can do the following

```
::ruby

File.open('index.html','r') do |fin|
  cf = ::ContentFinder.heuristic_finder(fin)
  cf.find! 
  puts cf.selected_html # The HTML of the content
  puts cf.selected_text # The text of the content
end

```

By installing this gem with bundler you can use it from the command line

```

$echo -ne "source 'https://rubygems.org'\ngem 'content_finder', git: 'https://github.com/hydrogen18/content_finder.git/'" > Gemfile
$bundle install

...output from bundle install...

$ curl --silent https://aphyr.com/posts/333-serializability-linearizability-and-locality | content_finder 
<div id="content">
<article class="primary post">
  <div class="backdrop">
...more html...

```