#!/usr/bin/env ruby

require_relative '../lib/solig'
sol2_docx = Document.new File.read 'SOL2-from-docx-with-edits.xml'
sol2_tei = Document.new File.read 'SOL2.xml'
artiklar_element = sol2_docx.root.elements.first
solig = Solig.new

# There has to be a better of doing that, but well!
def erase_element(element)
  element.elements.each do |one_element|
    element.delete one_element
  end
  element.text = ''
end

n = 444
title_docx = ''
File.read('list-of-screwups.txt').each_line do |id|
  id.strip!
  article_tei = XPath.first(sol2_tei, "//div[@xml:id='#{id}']")
  title_tei = XPath.first(article_tei, 'p/span[@type="fet"]').text
  puts "Found article to replace: #{title_tei}, looking for same in source ..."
  while title_docx != title_tei
    n += 1
    article_formatted = solig.unword(artiklar_element.elements[n])
    title_element_docx = XPath.first(article_formatted, 'head/placeName') 
    title_docx = title_element_docx.text if title_element_docx
    puts "  ... got #{title_docx} ..."
    byebug
  end
  puts "Got #{title_docx!}"
  erase_element article_tei
  article_tei.add_element article_formatted
end
