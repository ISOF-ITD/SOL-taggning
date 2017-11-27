#!/usr/bin/env ruby
require_relative '../lib/solig'
solig = Solig.new
sol2 = Document.new File.read File.expand_path '../../SOL2.xml', __FILE__

problems = File.open 'problems.txt', 'w'

(3..5919).each do |n|
  div = XPath.first(sol2, "/TEI/text/body/div[#{n}]")
  puts "Analysing #{XPath.first(div, 'head/placeName')}"
  begin
    solig.analyse_kursiv(div)
  rescue
    id = div.attributes['xml:id']
    puts "Problem!  xml:id == #{id}"
    problems.puts id
  end
end

problems.close
