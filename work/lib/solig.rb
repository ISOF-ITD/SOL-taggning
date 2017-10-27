require 'rexml/document'
require 'byebug'

class UnexpectedElement < StandardError; end
class UnexpectedLocation < StandardError; end

class Solig
  def process(line)
    final_dot = line =~ /\.$/
    sentences = line.split(/[\.→]/)
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
    first = array.first
    if first == 'tätort' || first == 'gravfält'
      span_element2 = REXML::Element.new 'span'
      span_element2.add_attribute 'type', 'locale'
      span_element2.text = first
      p_element.add_element span_element2
      p_element.add_text ', '
      array.shift
    end

    location_element = REXML::Element.new 'location'
    p_element.add_element location_element
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
        locs.each do |loc|
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

      else
        element =~ /^(.*) (.*)$/
        locale = $2
        if locale
          case locale
          when 'sn'
            tag = 'district'
            attr = 'socken'
          when 'hd'
            tag = 'district'
            attr = 'härad'
          when 'stad'
            tag = 'settlement'
            attr = 'stad'
          else
            raise UnexpectedLocation.new(locale)

            # @errors ||= []
            # @errors << locale
          end
        end

        if index == length - 1
          tag = 'region'
          attr = 'landskap'
        end

        tag_element = REXML::Element.new tag
        tag_element.add_attribute 'type', attr
        tag_element.add_text element
        location_element.add_element tag_element
      end
    end

    p_element.add_text('.' + remsentences) if remsentences
    p_element.add_text '.' if final_dot

    place_element
  end

  def batch(doc, output = STDOUT)
    retvalue = REXML::Document.new
    retvalue.add_element doc.root.name
    n = 0
    node = if doc.is_a? REXML::Document then doc.root else doc end # TODO Spec for that
    node.elements.each do |element|
      if element.name == 'p'
        retvalue.root.add_element process element.text
        n += 1
      else
        begin
          retvalue.root.add_element element
        rescue RuntimeError
          byebug
        end
      end
    end

    output.puts "Processed #{n} <p> element"
    retvalue
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

  def unword(element)
    div = REXML::Element.new 'div'
    p = REXML::Element.new 'p'

    state = :initial
    element.each_element('w:r') do |r|
      if state == :initial
        if REXML::XPath.first(r, 'w:rPr/w:b')
          head = REXML::Element.new 'head', div
          head.text = REXML::XPath.first(r, 'w:t').text
          state = :parstart
        else
          return element
        end
      elsif state == :parstart
        if REXML::XPath.first(r, 'w:t').text.strip == ''
        else
          div.add_text ' '
          div.add_element p
          start = REXML::XPath.first(r, 'w:t').text
          if start =~ /^(.*?)([\.→]).*$/
            location = $1.split ','
            separator = $2
            tail = $3
          else
            location = start.split ','
          end

          locale = location.shift
          locale_element = REXML::Element.new 'span', p
          locale_element.add_attribute 'type', 'locale'
          locale_element.text = locale
          p.add_text ', '
          location_element = REXML::Element.new 'location', p
          ct = location.count
          location.each_with_index do |loc, index|
            loc.strip =~ /(.*)\s+(.*)/
            locale = $2
            name = $1
            case locale
            when 'sn'
              tag = 'district'
              type = 'socken'
            when 'hd'
              tag = 'district'
              type = 'härad'
            when 'skg'
              tag = 'district'
              type = 'skeppslag'
            end
            if index == ct - 1
              tag = 'region'
              type = 'landskap'
            end
            unless tag
              tag = 'invalid'
              type = 'invalid-too'
            end
            loc_element = REXML::Element.new tag, location_element
            loc_element.add_attribute 'type', type
            loc_element.text = loc.strip
            location.add_text separator + tail if tail # FIXME Do the italic stuff like below and FIXME do sth with sep
            if index == ct - 1 && loc =~ /\s$/
              p.add_text ' '
            end
          end
          state = :remainder
        end
      elsif state == :remainder
        if REXML::XPath.first(r, 'w:rPr/w:i')
          span = REXML::Element.new 'span', p
          span.add_attribute 'style', 'italic'
          span.text = REXML::XPath.first(r, 'w:t').text
        else
          p.add_text REXML::XPath.first(r, 'w:t').text
        end
      end
    end

    div
  end
end
