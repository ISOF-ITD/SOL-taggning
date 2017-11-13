#!/usr/bin/env ruby

require_relative '../lib/solig'

solig = Solig.new
sol2 = REXML::Document.new File.read File.expand_path '../../SOL2-from-docx-with-edits.xml', __FILE__
paragrafer = sol2.root.elements.first

pars = solig.process_range paragrafer, (444..4299)

pars_file = File.open(File.expand_path('../../artiklarA-O.xml', __FILE__), 'w')
# pars_file.puts pars.to_s
pars.root.each_element do |element|
  pars_file.puts element
  pars_file.puts ''
end
pars_file.close
