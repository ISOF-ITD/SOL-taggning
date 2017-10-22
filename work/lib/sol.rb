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

      # byebug

      xml_strip += "<#{tag} type=\"#{attr}\">#{element}</#{tag}>"

      if index == length - 1
        xml_strip += '</location>'
      else
        xml_strip += ', '
      end
    end

    xml_strip
  end
end
