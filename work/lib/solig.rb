require 'rexml/document'
require 'byebug'

class UnexpectedElement < StandardError; end
class UnexpectedLocation < StandardError; end

class String
  @@uspaces = '[  ]' # FIXME Complete!
  @@landskap = [
    'Skåne', 'Blekinge', 'Öland', 'Småland', 'Halland',
    'Västergötland', 'Bohuslän', 'Dalsland', 'Gotland', 'Östergötland',
    'Södermanland', 'Närke', 'Värmland', 'Uppland', 'Västmandland',
    'Dalarna', 'Gästrikland', 'Hälsingland', 'Härjedalen', 'Medelpad',
    'Jämland', 'Ångermanland', 'Västerbotten', 'Lappland', 'Norrbotten',
  ]

  def ustrip
    gsub(/^#{@@uspaces}*/, '').gsub(/#{@@uspaces}*$/, '')
  end

  def uspace
    gsub(/#{@@uspaces}+/, ' ')
  end

  def is_landskap
    @@landskap.include? self
  end
end

class REXML::Element
  def add_italic_text(text)
    span = REXML::Element.new 'span', self
    span.add_attribute 'style', 'italic'
    span.add_text text
  end

  def add_locale(locale)
    span = REXML::Element.new 'span', self
    span.add_attribute 'type', 'locale'
    span.add_text locale
  end

  def add_location_element(loc)
    if loc.strip.is_landskap
      element = REXML::Element.new 'region', self
      element.add_attribute 'type', 'landskap'
      element.add_text loc.strip
      return
    else
      loc.strip =~ /(.*)\s+(.*)/
      locale = $2
      name_s_ = $1
    end

    ls = loc.split('och').map(&:strip)
    ls.each do |l|
      case locale
      when 'sn', 'snr'
        tag = 'district'
        type = 'socken'
      when 'hd'
        tag = 'district'
        type = 'härad'
      when 'skg'
        tag = 'district'
        type = 'skeppslag'
      when 'stad'
        tag = 'settlement'
        type = 'stad'
      else
        tag = 'invalid'
        type = 'invalid'
      end

      element = REXML::Element.new tag, self
      element.add_attribute 'type', type
      element.add_text l.strip
    end
  end

  def isitalic
    REXML::XPath.first(self, 'w:rPr/w:i')
  end

  def isbold
    REXML::XPath.first(self, 'w:rPr/w:b')
  end

  def text_bit
    t = REXML::XPath.first(self, 'w:t')
    t && t.text
  end
end

class Solig
  def unword(element)
    div = REXML::Element.new 'div'
    p = REXML::Element.new 'p'
    carryover = ''
    italic = ''

    state = :initial
    headword = ''
    element.each_element('w:r') do |r|
      if state == :initial
        if r.isbold
          rt = r.text_bit.uspace
          if rt.length > 0 && rt.ustrip == ''
            rt = ' '
          end
          headword += rt
        else
          headtag = REXML::Element.new 'head', div
          head = REXML::Element.new 'placeName', headtag
          head.text = headword.ustrip
          carryover = r.text_bit.uspace
          state = :locale
        end
      elsif state == :locale
        if r.text_bit.strip == ''
        else
          unless p.parent # FIXME Replace with an intermediate state or something
            div.add_text carryover
            div.add_element p
          end

          if r.text_bit =~ /^(.*?)([\.→])(.*)$/
            location = $1.split ','
            separator = $2
            tail = $3
          else
            location = r.text_bit.split ','
          end

          locale = location.shift
          while locale && locale.strip !~ /\s/ && !locale.strip.is_landskap
            p.add_locale locale.strip
            p.add_text ', '
            locale = location.shift
          end

          if locale
            location.unshift(locale)
          else
            next
          end

          location_element = REXML::Element.new 'location', p
          ct = location.count
          location.each_with_index do |loc, index|
            location_element.add_location_element loc

            if index == ct - 1
              if loc =~ /\s$/
                p.add_text ' '
              end

              if tail # FIXME Do the italic stuff like below and FIXME do sth with sep
                p.add_text separator
                p.add_text tail
              end
            end
          end

          state = :remainder
        end
      elsif state == :remainder
        if r.isitalic
          italic = r.text_bit
          state = :italic
        else
          p.add_text r.text_bit
        end
      elsif state == :italic
        if r.isitalic
          italic += r.text_bit
        else
          p.add_italic_text italic.strip
          p.add_text ' ' if italic =~ /\s$/
          p.add_text r.text_bit
          state = :remainder
        end
      end
    end

    div
  end
end
