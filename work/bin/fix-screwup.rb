#!/usr/bin/env ruby

require_relative '../lib/solig'
puts "Loading Word file ..."
sol2_docx = Document.new File.read 'SOL2-from-docx-with-edits.xml'
puts "... loaded.  Loading TEI file ..."
sol2_tei = Document.new File.read 'SOL2.xml'
puts "Loaded.  Now running!"
artiklar_element = sol2_docx.root.elements.first
solig = Solig.new

class Element
# There has to be a better of doing that, but well!
  def erase
    elements.each do |element|
      delete element
    end
    self.text = ''
  end
end

n = 444
title_docx = ''
File.read('list-of-screwups.txt').each_line do |id|
  id.strip!
  article_tei = XPath.first(sol2_tei, "//div[@xml:id='#{id}']")
  title_tei_element = XPath.first(article_tei, 'p/span[@type="fet"]')
  byebug unless title_tei_element
  title_tei = title_tei_element.text
  puts "Found article to replace: #{title_tei}, looking for same in source ..."
  while title_docx != title_tei
    n += 1
    article_formatted = solig.unword(artiklar_element.elements[n])
    title_element_docx = XPath.first(article_formatted, 'head/placeName') 
    title_docx = title_element_docx.text if title_element_docx
    puts "  ... got #{title_docx} ..."
  end
  puts "Got #{title_docx}!"
  article_tei.erase
  article_tei.add_element article_formatted
end

byebug
