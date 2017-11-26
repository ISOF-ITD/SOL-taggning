#!/usr/bin/env ruby
require_relative '../lib/solig'
solig = Solig.new
sol2 = Document.new File.read File.expand_path '../../SOL2.xml', __FILE__

(3..4000).each do |n|
  puts XPath.first(sol2, "/TEI/text/body/div[#{n}]/head/placeName")
end
