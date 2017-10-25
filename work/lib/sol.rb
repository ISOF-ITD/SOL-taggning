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
    place_element = REXML::Element.new 'div'
    head_element = REXML::Element.new 'head'
    placename_element = REXML::Element.new 'placeName'
    placename_element.text = $1
    place_element.add_element head_element
    head_element.add_element placename_element
    place_element.add_text ' '
    p_element = REXML::Element.new 'p'
    span_element = REXML::Element.new 'span'
    span_element.add_attribute 'type', 'locale'
    span_element.text = $2
    p_element.add_element span_element
    place_element.add_element p_element
    p_element.add_text ', '
    xml_strip = "<head><placeName>#{$1}</placeName></head> <p><span type='locale'>#{$2}</span>, "
    first = array.first
    if first == 'tätort' || first == 'gravfält'
      span_element2 = REXML::Element.new 'span'
      span_element2.add_attribute 'type', 'locale'
      span_element2.text = first
      p_element.add_element span_element2
      p_element.add_text ', '
      xml_strip += "<span type='locale'>#{first}</span>, "
      array.shift
    end
    location_element = REXML::Element.new 'location'
    p_element.add_element location_element
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
          tag_element = REXML::Element.new tag
          tag_element.add_attribute 'type', attr
          tag_element.add_text loc
          location_element.add_element tag_element
          "<#{tag} type='#{attr}'>#{loc}</#{tag}>"
        end

        tag_element = REXML::Element.new tag
        tag_element.add_attribute 'type', attr
        tag_element.add_text $1
        location_element.add_element tag_element
        loc_elts << "<#{tag} type='#{attr}'>#{$1}</#{tag}>"

        xml_strip += loc_elts.join
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

        tag_element = REXML::Element.new tag
        tag_element.add_attribute 'type', attr
        tag_element.add_text element
        location_element.add_element tag_element
        xml_strip += "<#{tag} type='#{attr}'>#{element}</#{tag}>"

        if index == length - 1
          xml_strip += '</location>'
        end
      end
    end

    p_element.add_text('.' + remsentences) if remsentences
    p_element.add_text '.' if final_dot
    xml_strip += '.' + remsentences if remsentences
    xml_strip += '.' if final_dot

    xml_strip + '</p>'
    place_element
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
