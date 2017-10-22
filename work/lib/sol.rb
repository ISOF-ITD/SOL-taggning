require 'byebug'

class Sol
  def process(line)
    array = line.split(',').map(&:strip)
    place = array.shift
    place =~ /^(.*) (.*)$/
    xml_strip = "<head><placeName>#{$1}</placeName></head> <P><locale>#{$2}</locale>, "
    first = array.first
    if first == 'tätort'
      xml_strip += '<locale>tätort</locale>, <location>, '
      array.shift
    end
    length = array.count
    array.each_with_index do |element, index|
      if element == 'tätort'
        xml_strip += '<locale>tätort</locale>, ' # FIXME Find all tätorter that are not locales
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

        # byebug

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
end
