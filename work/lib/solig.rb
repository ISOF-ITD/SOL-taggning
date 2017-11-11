require 'rexml/document'
require 'byebug'

include REXML

class UnexpectedElement < StandardError; end
class UnexpectedLocation < StandardError; end

class NilClass
  def uspace
    nil
  end

  def is_one_word?
    false
  end

  def is_locale?
    false
  end
end

class Hash
  def reverse
    reversed = { }
    each do |key, value|
      reversed[value] = key
    end
    reversed
  end
end

class String
  @@uspaces = '[   ]' # FIXME Complete!

  def ustrip
    strip.gsub(/^#{@@uspaces}*/, '').gsub(/#{@@uspaces}*$/, '')
  end

  def uspace
    gsub(/#{@@uspaces}+/, ' ')
  end

  def is_one_word?
    strip !~ /\s/
  end

  def is_landskap?
    Solig.is_landskap? self
  end

  def is_locale?
    self =~ /\\fd/ || is_one_word? && !strip.is_landskap?
  end
end

class Element
  def add_italic_text(text)
    span = Element.new 'span', self
    span.add_attribute 'type', 'kursiv'
    span.add_escaped_text text
  end

  def escape_text! # TODO A recursive version?
    savedtext = text
    self.text = ''
    add_escaped_text savedtext
  end

  def add_escaped_text(escaped_text)
    Solig.add_escaped_text self, escaped_text
  end

  def isitalic?
    XPath.first(self, 'w:rPr/w:i')
  end

  def isbold?
    XPath.first(self, 'w:rPr/w:b')
  end

  def text_bit
    t = XPath.first(self, 'w:t')
    t && Solig.escape(t.text)
  end
end

class Solig
  @@landskap = [
    'Skåne', 'Blekinge', 'Öland', 'Småland', 'Halland',
    'Västergötland', 'Bohuslän', 'Dalsland', 'Gotland', 'Östergötland',
    'Södermanland', 'Närke', 'Värmland', 'Uppland', 'Västmanland',
    'Dalarna', 'Gästrikland', 'Hälsingland', 'Härjedalen', 'Medelpad',
    'Jämtland', 'Ångermanland', 'Västerbotten', 'Lappland', 'Norrbotten',
  ]

  def self.is_landskap? string
    @@landskap.include? string
  end

  def self.landskap_regexp
    @@landskap_regexp ||= Regexp.new @@landskap.join('|')
  end

  def self.escape(text)
    text.gsub(/f\.d\./, '\\fd') if text
  end

  def initialize
    reset
  end

  def reset
    @state = :initial
    @currtext = ''
    @carryover = ''
  end

  def unword(element)
    reset
    @currelem = Element.new 'div'
    @currelem.add_attribute 'type', '?'
    p = Element.new 'p'
    first = true

    rs = element.each_element('w:r') { }.to_a
    r = rs.shift
    while r do
      # byebug
      case @state
      when :initial
        if r.isbold?
          collect_headword(r)

          r = rs.shift
        else
          # byebug
          @state = :head
        end
      when :head
        # byebug
        add_head_element(@carryover.ustrip)
        @carryover = r.text_bit.uspace
        @currelem.add_escaped_text ' '
        @currelem = Element.new 'p', @currelem
        @currtext = @carryover.strip
        @carryover = ''

        unless rs.first && rs.first.isitalic? # FIXME And something else?
          r = rs.shift
          @currtext += r.text_bit
        end
        while @currtext !~ /,/ && !(rs.first && rs.first.isitalic?) # Search for full first locale
          r = rs.shift
          @currtext += r.text_bit
        end

        @state = :first_locale
      when :first_locale
        # byebug
        add_locale_element @currtext.gsub /(.*?),.*/, '\1'
        @currelem.add_text ', '
        @currtext.gsub! /^.*?,\s*/, ''
        while @currtext !~ /[\.→]/ && !(rs.first && rs.first.isitalic?)
          r = rs.shift # !!!
          @currtext += r.text_bit
        end

        while @currtext =~ /(.*?),/ # Take as many locales in current run
          # byebug
          if $1.is_locale?
            add_locale_element $1
            @currelem.add_text ', '
            @currtext.gsub! /^[^,]*,\s*/, ''
          else
            break
          end
        end

        @state = :no_further_locales
      when :no_further_locales
        # byebug
        if @currtext =~ /(.*?)([\.→].*)/ # Search for end of run
          @currtext = $1
          @carryover = $2
        end

        init_location_elements
        @state = :location
      when :location
        # byebug
        while @currtext =~ /(.*?),/ # Take as many location elements in current run
          add_location_element $1
          @currtext.gsub! /^[^,]*,\s*/, ''
        end
        add_location_element @currtext
        @currelem = @currelem.parent
        @currelem.add_text ' ' if @currtext =~ /\s$/
        @currelem.add_text @carryover if @carryover
        # byebug
        r = rs.shift
        @carryover = ''
        @state = if r.isitalic? then :italic else :general end
        # byebug

#         byebug
#         if @carryover =~ /^(.*?)[\.→]/
#           location = $1.split ','
#           @carryover.gsub! /^[^\.→]*/, ''
#         elsif @carryover.is_a? String
#           location = @carryover.split ','
#         end
# 
#         location.select! { |loc| !loc.strip.empty? }
# 
#         # byebug
#         locale = location.shift
#         while first || locale.is_locale?
#           # byebug
#           @currelem.add_escaped_text ', ' unless first
#           add_locale_element locale.strip if locale
#           locale = location.shift
#           first = false
#         end
# 
#         if locale
#           @currelem.add_escaped_text ', '
#           location.unshift(locale)
#           @state = :location
#           @carryover = location.join(', ') + @carryover
#         elsif @carryover.length > 1
#           if @carryover =~ /[\.→]/
#             @state = :general
#             @currelem.add_text @carryover
#             @carryover = nil
#           else
#             @carryover = location.join(', ') + @carryover
#           end
#           r = rs.shift
#         else
#           r = rs.shift
#           @carryover = r.text_bit
#           next
#         end
#       when :location
#         add_location(r)
#         r = rs.shift
      when :general
        # byebug
        if r.isitalic?
          @carryover = r.text_bit
          @state = :italic
        else
          # byebug
          @currelem.add_escaped_text @carryover if @carryover
          @carryover = nil if @carryover
          @currelem.add_escaped_text r.text_bit
        end

        r = rs.shift
      when :italic
        # byebug
        if r.isitalic?
          @carryover += r.text_bit if r.text_bit
        else
          @currelem.add_italic_text @carryover.strip
          @currelem.add_escaped_text ' ' if @carryover =~ /\s$/
          if @carryover =~ /(\s*)$/ # TODO Idiom for that
            @carryover = $1
          else
            @carryover = nil
          end
          @currelem.add_escaped_text r.text_bit
          @state = :general
        end

        r = rs.shift
      end
    end

    # byebug

    r = Element.new 'w:r'
    rt = Element.new 'w:t', r
    rt.text = 'foo'
    add_location(r) if @carryover && @state == :location

    # if carryover
    #   if state == :remainder
    #     p.add_text carryover
    #   elsif state == :italic
    #     p.add_italic_text carryover
    #   end # FIXME else raise something
    # end

    @currelem.parent
  end

  def init_location_elements
    @currelem = Element.new 'location', @currelem
  end

  def add_location(r) # FIXME Some spec (?)
    byebug
    @carryover =~ /^([^\.→]*?)/
    location = $1.split(', ').select { |loc| !loc.strip.empty? }
    @carryover.gsub! /^([^\.→]*)/, ''
    location_element = Element.new 'location', @currelem
    ct = location.count
    location.each_with_index do |loc, index|
      @currelem = location_element
      add_location_element loc
      @currelem = @currelem.parent

      if index == ct - 1
        if loc =~ /\s$/
          @currelem.add_escaped_text ' '
        end
      end
    end

    @currelem.add_escaped_text @carryover

    @carryover = r.text_bit
    @state = if r.isitalic? then :italic else :general end
  end

  def collect_headword(r)
    rt = r.text_bit.uspace
    if rt.length > 0 && rt.ustrip == ''
      rt = ' '
    end
    @carryover += rt
  end

  # FIXME Figure out what the deal is with w:noBreakHyphen?
  def self.add_escaped_text(element, text)
    element.add_text text.gsub(/\\fd/, 'f.d.') if text # FIXME Extract that somewhere
  end

  def add_head_element(headword)
    headtag = Element.new 'head', @currelem
    head = Element.new 'placeName', headtag
    head.text = headword
    @currelem.add_attribute 'xml:id', headword.gsub(/ /, '_').gsub(/,/, '.').gsub(/^-/, '_')
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
      when Solig.landskap_regexp
        tag = 'region'
        type = 'landskap'
      else
        tag = 'invalid'
        type = 'invalid'
      end

      location_element = Element.new tag, @currelem
      location_element.add_attribute 'type', type
      location_element.add_escaped_text l.strip
    end
  end

  def add_locale_element(locale)
    span = Element.new 'span', @currelem
    span.add_attribute 'type', 'locale'
    span.add_escaped_text locale
  end
end
