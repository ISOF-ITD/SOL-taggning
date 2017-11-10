require 'rexml/document'
require 'byebug'

class UnexpectedElement < StandardError; end
class UnexpectedLocation < StandardError; end

class NilClass
  def uspace
    nil
  end
end

class String
  @@uspaces = '[  ]' # FIXME Complete!
  @@landskap = [
    'Skåne', 'Blekinge', 'Öland', 'Småland', 'Halland',
    'Västergötland', 'Bohuslän', 'Dalsland', 'Gotland', 'Östergötland',
    'Södermanland', 'Närke', 'Värmland', 'Uppland', 'Västmanland',
    'Dalarna', 'Gästrikland', 'Hälsingland', 'Härjedalen', 'Medelpad',
    'Jämtland', 'Ångermanland', 'Västerbotten', 'Lappland', 'Norrbotten',
  ]

  def ustrip
    strip.gsub(/^#{@@uspaces}*/, '').gsub(/#{@@uspaces}*$/, '')
  end

  def uspace
    gsub(/#{@@uspaces}+/, ' ')
  end

  def is_landskap
    @@landskap.include? self
  end

  def self.landskap_regexp
    @@landskap_regexp ||= Regexp.new @@landskap.join('|')
  end
end

class REXML::Element
  def add_italic_text(text)
    span = REXML::Element.new 'span', self
    span.add_attribute 'type', 'kursiv'
    span.add_escaped_text text
  end

  def escape_text! # TODO A recursive version?
    savedtext = text
    self.text = ''
    add_escaped_text savedtext
  end

  def add_locale(locale)
    span = REXML::Element.new 'span', self
    span.add_attribute 'type', 'locale'
    span.add_escaped_text locale
  end

  # FIXME Figure out what the deal is with w:noBreakHyphen?
  def add_escaped_text(text)
    add_text text.gsub(/\\fd/, 'f.d.') if text # FIXME Extract that somewhere
  end

  def add_head_element(headword, r)
    headtag = REXML::Element.new 'head', self
    head = REXML::Element.new 'placeName', headtag
    head.text = headword.ustrip
    add_attribute 'xml:id', headword.ustrip.gsub(/ /, '_').gsub(/,/, '.').gsub(/^-/, '_')
    r.text_bit.uspace
  end

  def add_location_element(loc)
    if loc.strip =~ /.*\s+(.*)/ then
      locale = $1
    else
      locale = loc
    end

    ls = loc.split('och').map(&:strip)
    ls.each do |l|
      case locale
      when 'sn', 'snr'
        tag = 'district'
        type = 'socken'
      when 'lfs'
        tag = 'district'
        type = 'landsförsamling'
      when 'hd'
        tag = 'district'
        type = 'härad'
      when 'skg'
        tag = 'district'
        type = 'skeppslag'
      when 'stad'
        tag = 'settlement'
        type = 'stad'
      when String.landskap_regexp
        tag = 'region'
        type = 'landskap'
      else
        tag = 'invalid'
        type = 'invalid'
      end

      element = REXML::Element.new tag, self
      element.add_attribute 'type', type
      element.add_escaped_text l.strip
    end
  end

  def isitalic?
    REXML::XPath.first(self, 'w:rPr/w:i')
  end

  def isbold?
    REXML::XPath.first(self, 'w:rPr/w:b')
  end

  def text_bit
    t = REXML::XPath.first(self, 'w:t')
    t && Solig.escape(t.text)
  end
end

class Solig
  def self.escape(text)
    text.gsub(/f\.d\./, '\\fd') if text
  end

  def initialize
    @state = :initial
  end

  def unword(element)
    div = REXML::Element.new 'div'
    div.add_attribute 'type', '?'
    p = REXML::Element.new 'p'
    carryover = ''
    italic = ''
    first = true

    state = :initial
    headword = ''
    element.each_element('w:r') do |r|
      # byebug
      if state == :initial
        if r.isbold?
          rt = r.text_bit.uspace
          if rt.length > 0 && rt.ustrip == ''
            rt = ' '
          end
          headword += rt
        else
          # byebug
          carryover = div.add_head_element(headword, r)
          state = :locale
        end
      elsif state == :locale
        # byebug
        t = r.text_bit
        unless t.strip == ''
          unless p.parent # FIXME Replace with an intermediate state or something
            div.add_escaped_text ' '
            div.add_element p
            t = carryover.strip + t
          end

          if t =~ /^(.*?)([\.→])(.*)$/
            location = $1.split ','
            separator = $2
            tail = $3
          else
            location = t.split ','
          end

          location.select! { |loc| !loc.strip.empty? }

          locale = location.shift
          while first || locale =~ /\\fd/ || locale && locale.strip !~ /\s/ && !locale.strip.is_landskap
            # byebug
            p.add_escaped_text ', ' unless first
            p.add_locale locale.strip
            locale = location.shift
            first = false
          end

          if locale
            p.add_escaped_text ', '
            location.unshift(locale)
          else
            p.add_text separator
            if tail =~ /[\.→]/
              state = :general
              p.add_text tail
              carryover = nil
            end
            next
          end

          state = :location
          carryover = [location, separator, tail]
        end
        # byebug
      elsif state == :location
        retvalue = add_location(p, r, carryover)
        state = retvalue.first
        carryover = retvalue[1]
        italic = retvalue.last
      elsif state == :general
        if r.isitalic?
          italic = r.text_bit
          state = :italic
        else
          # byebug
          p.add_escaped_text carryover if carryover
          carryover = nil if carryover
          p.add_escaped_text r.text_bit
        end
      elsif state == :italic
        if r.isitalic?
          italic += r.text_bit if r.text_bit
        else
          p.add_italic_text italic.strip
          carryover = nil
          p.add_escaped_text ' ' if italic =~ /\s$/
          p.add_escaped_text r.text_bit
          state = :general
        end
      end
    end

    # byebug

    r = REXML::Element.new 'w:r'
    rt = REXML::Element.new 'w:t', r
    rt.text = 'foo'
    add_location(p, r, carryover) if carryover && state == :location

    # if carryover
    #   if state == :remainder
    #     p.add_text carryover
    #   elsif state == :italic
    #     p.add_italic_text carryover
    #   end # FIXME else raise something
    # end

    div
  end

  def add_location(p, r, carryover = nil) # FIXME Some spec (?)
    state = nil

    if r.text_bit
      unless r.text_bit.strip == ''
        location = carryover.first
        separator = carryover[1]
        tail = carryover.last
        location_element = REXML::Element.new 'location', p
        ct = location.count
        location.each_with_index do |loc, index|
          location_element.add_location_element loc

          if index == ct - 1
            if loc =~ /\s$/
              p.add_escaped_text ' '
            end
          end
        end

        if tail
          p.add_escaped_text separator
          p.add_escaped_text tail
        end

        italic = r.text_bit if r.isitalic?
        carryover = r.text_bit
        state = if r.isitalic? then :italic else :general end
      end
    end

    [state, carryover, italic]
  end
end
