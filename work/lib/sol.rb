require 'rexml/document'
require 'byebug'

class UnexpectedElement < StandardError; end

class Sol
  def process(line)
    final_dot = line =~ /\.$/
    sentences = line.split('.')
    first_sentence = sentences.shift
    remsentences = sentences.join('.') if sentences.count > 0
    array = first_sentence.split(',').map(&:strip)
    place = array.shift
    place =~ /^(.*) (.*)$/
    xml_strip = "<head><placeName>#{$1}</placeName></head> <p><locale>#{$2}</locale>, "
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

    xml_strip += '.' + remsentences if remsentences
    xml_strip += '.' if final_dot

    xml_strip + '</p>'
  end

  def unweave(table)
    doc = REXML::Document.new(table)
    result = [[], []]
    doc.root.elements.each do |element|
      elts = element.elements
      result.first << elts[1].text
      result.last << elts[2].text
    end

    result.map { |res| res.join(' ') }.join(' ')
  end

  def unlist(list)
    doc = REXML::Document.new(list)
    result = []

    if doc.root.name == 'root'
      doc.root.elements.each do |element|
        if element.name == 'L'
          element.elements.each do |elt|
            result << '  <p>' + elt.elements[2].text + '</p>'
          end
        elsif element.name == 'p'
          result << '  <p>' + element.text + '</p>'
        elsif element.name == 'figure'
          graphic = element.elements.first
          raise UnexpectedElement.new(graphic.name) unless graphic.name == 'graphic'
          url = graphic.attributes['url']
          result << "  <figure><graphic url=\"#{url}\" /></figure>"
        else
          raise UnexpectedElement.new(element.name)
        end
      end
    else
      doc.root.elements.each do |element|
        result << element.elements[2].text
      end
    end

    "<root>\n" + result.join("\n\n") + "\n</root>"
  end

  def load
    REXML::Document.new(File.read('SOL2.xml')).root.elements[2].elements[2].elements[2].elements[74]
  end
end
