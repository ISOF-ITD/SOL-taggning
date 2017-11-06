$LOAD_PATH << File.expand_path('../../lib', __FILE__)
require 'solig'

def loadparagraph(id)
  featdir = File.expand_path('../fixtures/w:p', __FILE__)
  docstring = '<w:document xmlns:w="http://schemas.openxmlformats.org/2006/wordprocessml/2006/main" xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml">' +
    File.read(File.join(featdir, id + '.xml')) +
    '</w:document>'
  doc = REXML::Document.new docstring
  doc.root.elements.first
end
