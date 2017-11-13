#!/usr/bin/env ruby

require_relative '../lib/solig'

solig = Solig.new
sol2 = REXML::Document.new File.read File.expand_path '../../SOL2-from-docx-with-edits.xml', __FILE__
paragrafer = sol2.root.elements.first

pars = solig.process_range (444..4299)

pars_file = File.open(File.expand_path('../../artiklarA-O.xml', __FILE__), 'w')
pars_file.puts pars.to_s
pars_file.close
