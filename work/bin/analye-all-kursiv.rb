#!/usr/bin/env ruby
require_relative '../lib/solig'
solig = Solig.new
sol2 = Document.new File.read File.expand_path '../../SOL2.xml', __FILE__

problems = File.open 'problems.txt', 'w'

newsol = File.open 'newSOL2.xml', 'w'

(3..5919).each do |n|
  div = XPath.first(sol2, "/TEI/text/body/div[#{n}]")
  puts "Analysing #{XPath.first(div, 'head/placeName')}"
  begin
    retvalue = solig.analyse_kursiv(div)
    newsol.puts retvalue
    newsol.puts ''
  rescue
    id = div.attributes['xml:id']
    puts "Problem!  xml:id == #{id}"
    problems.puts id
    newsol.puts div
    newsol.puts ''
  end
end

newsol.close
problems.close
