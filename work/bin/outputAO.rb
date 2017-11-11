#!/usr/bin/env ruby

require_relative '../lib/solig'

solig = Solig.new
sol2 = REXML::Document.new File.read File.expand_path '../../SOL2-from-docx-with-edits.xml', __FILE__
paragrafer = sol2.root.elements.first.elements
pars = File.open(File.expand_path('../../artiklarA-O.xml', __FILE__), 'w')
(444..4299).each do |paragraf|
  pars.puts solig.unword paragrafer[paragraf]
  pars.puts ''
end

pars.close
