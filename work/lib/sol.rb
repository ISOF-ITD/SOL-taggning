require 'rexml/document'
require 'byebug'

class Sol
  def process(line)
    array = line.split(',').map(&:strip)
    place = array.shift
    place =~ /^(.*) (.*)$/
    xml_strip = "<head><placeName>#{$1}</placeName></head> <P><locale>#{$2}</locale>, "
    first = array.first
    if first == 'tätort' || first == 'gravfält'
      xml_strip += "<locale>#{first}</locale>, "
      array.shift
    end
    xml_strip += '<location>'
    length = array.count
    array.each_with_index do |element, index|
      if element =~ / och /
        locs = element.split(' och ').map(&:strip)
        locs.last =~ /^(.*) (.*)$/
        locale = $2
        case locale
        when 'snr'
          tag = 'district'
          attr = 'socken'
        when 'hd'
          tag = 'district'
          attr = 'härad'
        end

        locs.pop
        loc_elts = locs.map do |loc|
          "<#{tag} type=\"#{attr}\">#{loc}</#{tag}>"
        end

        loc_elts << "<#{tag} type=\"#{attr}\">#{$1}</#{tag}>"

        xml_strip += loc_elts.join(' och ') # FIXME Unlikely to be correct for more than two!
        xml_strip += " #{locale}, "
      else
        element =~ /^(.*) (.*)$/
        locale = $2
        case locale
        when 'sn'
          tag = 'district'
          attr = 'socken'
        when 'hd'
          tag = 'district'
          attr = 'härad'
        end

        if index == length - 1
          tag = 'region'
          attr = 'landskap'
        end

        xml_strip += "<#{tag} type=\"#{attr}\">#{element}</#{tag}>"

        if index == length - 1
          xml_strip += '</location>'
        else
          xml_strip += ', '
        end
      end
    end

    xml_strip
  end

  def unweave(table)
    doc = REXML::Document.new(table)
    result = [[], []]
    doc.root.elements.each do |element|
      elts = element.elements
      result.first << elts.first.text
      byebug
      result.last << elts.last.text
    end

    final_result = [result.first.join(' '), result.last.join(' ')].join(' ')
    byebug

    'This line is supposed to go with this line here while that line has to go with that one over there'
  end
end
