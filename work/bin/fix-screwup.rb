#!/usr/bin/env ruby

require_relative '../lib/solig'
puts "Laddar Word filen..."
sol2_docx = Document.new File.read 'SOL2-from-docx-with-edits.xml'
puts "... laddar.  Laddar TEI filen..."
sol2_tei = Document.new File.read 'SOL2.xml'
puts "Laddad.  Kör..."
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
  unless title_tei_element
    head_element = XPath.first(article_tei, 'head')
    next if head_element
  end
  title_tei = title_tei_element.text
  puts "Hittat en artikel att ersätta: #{title_tei}, söker densamma i källan..."
  while title_docx != title_tei
    n += 1
    article_formatted = solig.unword(artiklar_element.elements[n])
    title_element_docx = XPath.first(article_formatted, 'head/placeName') 
    title_docx = title_element_docx.text if title_element_docx
    puts "  ... fick #{title_docx}..."
  end
  puts "Fick #{title_docx}!"
  article_tei.erase
  article_tei.add_element article_formatted
end

byebug
