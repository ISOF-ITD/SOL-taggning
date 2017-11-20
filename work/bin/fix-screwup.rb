#!/usr/bin/env ruby

require_relative '../lib/solig'
sol2_docx = Document.new File.read 'SOL2-from-docx-with-edits.xml'
sol2_tei = Document.new File.read 'SOL2.xml'

File.read('list-of-screwups.txt').each_line do |id|
  article_docx
end
