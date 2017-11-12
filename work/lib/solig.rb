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

  def wtext
    ''
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
    Solig.is_locale? self
  end
end

class Element
  def has_invalid?
    XPath.first(self, '//invalid')
  end

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

  def wtext
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

  @@escape_sequences = {
    'f.d.' => '\\fd',
  }

  @@locale_words = [
    /\\fd/,
    /^nu\s/,
    /^samt\s/,
    /^och\s/,
  ]

  def self.is_landskap? string
    @@landskap.include? string
  end

  def self.landskap_regexp
    @@landskap_regexp ||= Regexp.new @@landskap.join('|')
  end

  def self.is_locale? string
    @@locale_words.each do |word|
      return true if string =~ word
    end

    string.is_one_word? && !string.strip.is_landskap?
  end

  def self.escape(text)
    if text
      retvalue = text
      @@escape_sequences.each do |abbrev, escape|
        retvalue.gsub!(abbrev, escape)
      end
    end

    retvalue
  end

  # FIXME Figure out what the deal is with w:noBreakHyphen?
  def self.add_escaped_text(element, text)
    if text
      copy = text
      @@escape_sequences.reverse.each do |escape, abbrev|
        copy.gsub! escape, abbrev
      end
      element.add_text copy
    end
  end

  def initialize
    reset
  end

  def reset
    @state = :initial
    @currtext = ''
    @carryover = ''
    @rs = []
    @r = ''
  end

  def unword(element)
    reset
    @currelem = Element.new 'div'
    @currelem.add_attribute 'type', '?'

    @rs = element.each_element('w:r') { }.to_a
    @r = @rs.shift
    while @r do
      # byebug
      case @state
      when :initial
        process_head

        @state = :first_locale
      when :first_locale
        process_locales

        @state = :location
      when :location
        process_location
        next unless @r
        @state = if @r.isitalic? then :italic else :general end
      when :general
        process_general_text
      when :italic
        process_italic
      end
    end

    flush_text

    @currelem.root
  end

  def process_head
    while @r.isbold?
      collect_headword(@r)
      @r = @rs.shift
    end

    # Set head
    add_head_element(@currtext.ustrip)
    @currelem.add_escaped_text ' '
    @currtext = @r.wtext.uspace.strip
    @currelem = Element.new 'p', @currelem

    unless @rs.first && @rs.first.isitalic? # FIXME And something else?
      @r = @rs.shift
      @currtext += @r.wtext if @r.wtext
    end
    while @currtext !~ /,/ && !(@rs.first && @rs.first.isitalic?) # Search for full first locale
      @r = @rs.shift
      break unless @r
      @currtext += @r.wtext if @r.wtext
    end
  end

  def process_locales
    add_locale_element @currtext.gsub /(.*?)[,\.→].*/, '\1'
    if @currtext =~ /,/
      @currelem.add_text ', '
      @currtext.gsub! /^.*?,\s*/, ''
    else
      @currtext.gsub! /^.*?([\.→])/, '\1'
    end
    while @currtext !~ /[\.→]/ && !(@rs.first && @rs.first.isitalic?)
      @r = @rs.shift
      @currtext += @r.wtext if @r.wtext
    end

    while @currtext =~ /(.*?),/ # Take as many locales in current run
      if $1.is_locale?
        add_locale_element $1
        @currelem.add_text ', '
        @currtext.gsub! /^[^,]*,\s*/, ''
      else
        break
      end
    end

    # No more locales from this point on.
    if @currtext =~ /(.*?)([\.→].*)/ # Search for end of run
      @currtext = $1
      @carryover = $2
    end
  end

  def process_location
    init_location_elements
    while @currtext =~ /(.*?),/ # Take as many location elements in current run
      add_location_element $1
      @currtext.gsub! /^[^,]*,\s*/, ''
    end
    add_location_element @currtext
    @currelem = @currelem.parent
    @currelem.add_text ' ' if @currtext =~ /\s$/
    @currelem.add_text @carryover if @carryover

    @r = @rs.shift
    @currtext = ''
  end

  def process_general_text
    if @r.isitalic?
      @currelem.add_escaped_text @currtext
      @currtext = @r.wtext
      @state = :italic
    else
      @currtext += @r.wtext if @r.wtext
    end

    @r = @rs.shift
  end

  def process_italic
    if @r.isitalic?
      @currtext += @r.wtext if @r.wtext
    else
      @currelem.add_text ' ' if @currtext =~ /^\s/
      @currelem.add_italic_text @currtext.strip
      @currtext = if @currtext =~ /\s$/ then ' ' else '' end
      @currtext += @r.wtext if @r.wtext
      @state = :general
    end

    @r = @rs.shift
  end

  def flush_text
    add_locale_element @currtext if @state == :first_locale
    @currelem.add_escaped_text @currtext if @state == :general
    # @currelem.add_italic_text @currtext if @state == :italic
    location = XPath.first(@currelem.root, '//location')
    location.remove if location.to_s == '<location/>'
  end

  def init_location_elements
    @currelem = Element.new 'location', @currelem
  end

  def collect_headword(r)
    rt = r.wtext.uspace
    if rt.length > 0 && rt.ustrip == ''
      rt = ' '
    end
    @currtext += rt
  end

  def add_head_element(head)
    head_element = Element.new 'head', @currelem
    place_name_element = Element.new 'placeName', head_element
    place_name_element.text = head
    @currelem.add_attribute 'xml:id', head.gsub(/ /, '_').gsub(/,/, '.').gsub(/^-/, '_')
  end

  def add_location_element(location)
    if location.strip =~ /.*\s+(.*)/ then
      locale = $1
    else
      locale = location
    end

    locations = location.split('och').map(&:strip)
    locations.each do |location|
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
      location_element.add_escaped_text location.strip
    end
  end

  def add_locale_element(locale)
    span = Element.new 'span', @currelem
    span.add_attribute 'type', 'locale'
    span.add_escaped_text locale.strip
  end
end
