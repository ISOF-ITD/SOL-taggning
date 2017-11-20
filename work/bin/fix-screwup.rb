#!/usr/bin/env ruby

require_relative '../lib/solig'
# sol2_docx = Document.new File.read 'SOL2-from-docx-with-edits.xml'
sol2_tei = Document.new File.read 'SOL2.xml'

File.read('list-of-screwups.txt').each_line do |id|
  id.strip!
  article_tei = XPath.first(sol2_tei, "//div[@xml:id='#{id}']")
  title = XPath.first(article_tei, 'head/placeName').title
  puts title
  byebug
end
