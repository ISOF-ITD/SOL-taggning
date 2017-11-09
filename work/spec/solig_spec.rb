require 'spec_helper'

describe NilClass do
  describe '#uspace' do
    it "returns nil|" do
      expect(nil.uspace).to be_nil
    end

    it "doesn’t crash" do
      expect { nil.uspace }.not_to raise_error
    end
  end
end

describe String do
  let(:ox) { "Oxie härad " } # With trailing U+2003 EM SPACE and U+2005 FOUR-PER-EM SPACE in the middle

  describe '#ustrip' do
    it "strips all Unicode space characters" do
      expect(ox.ustrip).to eq "Oxie härad"
    end
  end

  describe '#uspace' do
    it "replaces all Unicode space characters" do
      expect(ox.uspace).to eq "Oxie härad "
    end
  end

  describe '#is_landskap' do
    it "returns true if self is a landskap name" do
      expect('Uppland'.is_landskap).to be_truthy
    end

    it "returns false otherwise" do
      expect('talgoxe'.is_landskap).to be_falsey
    end

    it "has an exclusive list of landskap" do
      landskap = String.class_variable_get(:@@landskap)
      expect(landskap.count).to eq 25
      expect(landskap[1]).to eq 'Blekinge'
    end
  end

  describe '.landskap_regexp' do
    it "returns the landskap regexp" do
      expect(String.landskap_regexp).to be_a Regexp
    end

    it "matches Småland" do
      expect('Småland' =~ String.landskap_regexp).to be_truthy
    end

    it "doesn’t match Värend" do
      expect('Värend' =~ String.landskap_regexp).to be_falsey
    end

    it "doesn’t match Jönköping" do
      expect('Jönköping' =~ String.landskap_regexp).to be_falsey
    end

    it "caches the regexp" do
      String.landskap_regexp
      expect(String.class_variable_get(:@@landskap_regexp)).not_to be_nil
    end

    it "is not anchored" do
      expect('Småland och Västergötland' =~ String.landskap_regexp).to be_truthy
    end

    it "... really not!" do
      expect(' Skåne' =~ String.landskap_regexp).to be_truthy
    end
  end# TODO
end

describe REXML::Element do
  describe '#add_italic_text' do
    it "adds italic text" do
      foo = REXML::Document.new('<doc>foo</doc>').root

      foo.add_text ' '
      foo.add_italic_text 'bar'
      foo.add_text ' quux'

      expect(foo.to_s).to eq "<doc>foo <span type='kursiv'>bar</span> quux</doc>"
    end

    it "calls #add_escaped_text" do
      doc = REXML::Document.new('<doc>content</doc>')
      expect(doc.root).to receive(:add_escaped_text).with('a \\fd b')
      doc.root.add_escaped_text('a \\fd b')
    end
  end

  describe '#escape_text!' do
    it "escapes the text" do
      doc = REXML::Document.new('<doc>x \\fd y</doc>')
      doc.root.escape_text!
      expect(doc.root.text).to eq 'x f.d. y'
    end
  end

  describe '#add_locale' do
    it "adds a locale" do
      styra = REXML::Document.new('<div><head>Styra</head> <p></p></div>')
      p = REXML::XPath.first(styra, 'div/p')

      p.add_locale 'sn'

      expect(styra.to_s).to eq "<div><head>Styra</head> <p><span type='locale'>sn</span></p></div>"
    end
  end

  describe '#add_location_element' do
    it "adds a location element" do
      styra = REXML::Document.new "<div><head>Styra</head> <p><span type='locale'>sn</span> <location></location></p></div>"
      p = REXML::XPath.first(styra, 'div/p/location')

      p.add_location_element 'Aska hd'

      expect(styra.to_s).to eq "<div><head>Styra</head> <p><span type='locale'>sn</span> <location><district type='härad'>Aska hd</district></location></p></div>"
    end
  end

  describe '#isitalic?' do
    it "returns true if text bit is italic" do
      doc = REXML::Document.new "<w:document xmlns:w='somelink'><w:r><w:rPr><w:i /></w:rPr></w:r></w:document>"
      text = doc.root.elements.first
      expect(text.isitalic?).to be_truthy
    end

    it "returns false otherwise" do
      doc = REXML::Document.new "<w:document xmlns:w='ns'><w:r><w:rPr></w:rPr></w:r></w:document>"
      text = doc.root.elements.first
      expect(text.isitalic?).to be_falsey
    end

    it "doesn’t crash if element doesn’t conform to the .docx format" do
      doc = REXML::Document.new "<w:document xmlns:w='ns'><w:p></w:p></w:document>"
      text = doc.root.elements.first
      expect { text.isitalic? }.to_not raise_error
    end
  end

  describe '#isbold?' do
    it "returns true if text bit is bold" do
      doc = REXML::Document.new "<w:document xmlns:w=''><w:r><w:rPr><w:b /></w:rPr></w:r></w:document>"
      bold = doc.root.elements.first
      expect(bold.isbold?).to be_truthy
    end

    it "returns false otherwise" do
      doc = REXML::Document.new "<w:document xmlns:w=''><w:r><w:rPr></w:rPr></w:r></w:document>"
      notbold = doc.root.elements.first
      expect(notbold.isbold?).to be_falsey
    end

    it "doesn’t crash if element doesn’t have an rPr child" do
      doc = REXML::Document.new "<w:document xmlns:w=''><w:p></w:p></w:document>"
      not_a_text_bit = doc.root.elements.first
      expect(not_a_text_bit.isbold?).to be_falsey
    end
  end

  describe '#text_bit' do
    it "returns the text bit" do
      doc = REXML::Document.new "<w:document xmlns:w=''><w:r><w:t>foo</w:t></w:r></w:document>"
      bit = doc.root.elements.first
      expect(bit.text_bit).to eq 'foo'
    end

    it "doesn’t crash if element doesn’t contain a text bit" do
      doc = REXML::Document.new "<w:document xmlns:w=''><w:p>bar</w:p></w:document>"
      bit = doc.root.elements.first
      expect { bit.text_bit }.to_not raise_error
    end

    it "returns nil if element doesn’t contain a text bit" do
      doc = REXML::Document.new "<w:document xmlns:w=''><w:p>quux</w:p></w:document>"
      bit = doc.root.elements.first
      expect(bit.text_bit).to be_nil
    end

    it "calls Solig.escape" do
      doc = REXML::Document.new "<w:document xmlns:w=''><w:p><w:r><w:t>foo \\fd bar</w:t></w:r></w:p></w:document>"
      bit = REXML::XPath.first(doc, '/w:document/w:p/w:r')
      expect(Solig).to receive(:escape).with('foo \\fd bar')
      bit.text_bit
    end
  end

  describe '#add_escaped_text' do
    it "interprets the escape sequences" do
      doc = REXML::Document.new "<doc><p></p></doc>"
      element = doc.root.elements.first
      element.add_escaped_text "foo \\fd bar"
      expect(element.text).to eq "foo f.d. bar"
    end

    it "doesn’t crash on nil input" do
      root = REXML::Document.new("<doc></doc>").root
      expect { root.add_escaped_text nil }.not_to raise_error
    end
  end
end

describe Solig do
  let(:solig) { Solig.new }

  describe '.escape' do
    it "replaces “f.d.” with \\fd" do
      expect(Solig.escape('lantbruksuniversitet, f.d. gods')).to eq 'lantbruksuniversitet, \\fd gods'
    end

    it "doesn’t crash on nil input" do
      expect { Solig.escape(nil) }.not_to raise_error
    end
  end

  describe '#unword' do
    it "dismantles the Word XML structure" do
      bro = loadparagraph '1023-bro'
      pending "This is going to be painful"
      expect(solig.unword(bro).to_s).to eq "<div><head><placeName>Bro</placeName></head> <p><span type='locale'>sn</span>, <location><district type='skeppslag'>Bro och Vätö skg</district><region type='landskap'>Uppland</region></location> → <span type='kursiv'>Roslags-Bro</span>.</p></div>"
    end

    it "processes a parish without a härad" do
      husby = loadparagraph '2498-husby'
      form = solig.unword(husby)
      expect(form.to_s).to be =~ /^<div xml:id='Husby' type='\?'><head><placeName>Husby<\/placeName><\/head> <p><span type='locale'>sn<\/span>, <span type='locale'>tätort<\/span>, <location><region type='landskap'>Dalarna<\/region><\/location>/
    end

    it "processes a parish with an extra locale" do
      hurva = loadparagraph '2490-hurva'
      form = solig.unword(hurva)
      expect(form.to_s).to be =~ /^<div xml:id='Hurva' type='\?'><head><placeName>Hurva<\/placeName><\/head> <p><span type='locale'>sn<\/span>, <span type='locale'>tätort<\/span>, <location><district type='härad'>Frosta hd<\/district><region type='landskap'>Skåne<\/region><\/location>/
    end

    it "processes a point with an extra locale" do
      vätteryd = loadparagraph '6338-vätteryd'
      form = solig.unword(vätteryd)
      expect(form.to_s).to be =~ /^<div xml:id='Vätteryd' type='\?'><head><placeName>Vätteryd<\/placeName><\/head> <p><span type='locale'>torp<\/span>, <span type='locale'>gravfält<\/span>, <location><district type='socken'>Norra Mellby sn<\/district><district type='härad'>Västra Göinge hd<\/district><region type='landskap'>Skåne<\/region><\/location>/
    end

    it "processes a parish with a compound name" do
      västra_vram = loadparagraph '6331-västra-vram'
      form = solig.unword(västra_vram)
      expect(form.to_s).to be =~ /^<div xml:id='Västra_Vram' type='\?'><head><placeName>Västra Vram<\/placeName><\/head> <p><span type='locale'>sn<\/span>, <location><district type='härad'>Gärds hd<\/district><region type='landskap'>Skåne<\/region><\/location>/
    end

    it "processes a simple parish" do
      västrum = loadparagraph '6333-västrum'
      form = solig.unword(västrum)
      expect(form.to_s).to be =~ /<div xml:id='Västrum' type='\?'><head><placeName>Västrum<\/placeName><\/head> <p><span type='locale'>sn<\/span>, <location><district type='härad'>Södra Tjusts hd<\/district><region type='landskap'>Småland<\/region><\/location>/
    end

    it "handles the case of two härad" do
      kinnekulle = loadparagraph '3006-kinnekulle'
      form = solig.unword(kinnekulle)
      expect(form.to_s).to be =~ /^<div xml:id='Kinnekulle' type='\?'><head><placeName>Kinnekulle<\/placeName><\/head> <p><span type='locale'>berg<\/span>, <location><district type='härad'>Kinne<\/district><district type='härad'>Kinnefjärdings hd<\/district><region type='landskap'>Västergötland<\/region><\/location>/
    end 

    it "handles the case of two socknar" do
      kivik = loadparagraph '3015-kivik'
      form = solig.unword(kivik)
      expect(form.to_s).to be =~ /<div xml:id='Kivik' type='\?'><head><placeName>Kivik<\/placeName><\/head> <p><span type='locale'>tätort<\/span>, <location><district type='socken'>Södra Mellby<\/district><district type='socken'>Vitaby snr<\/district><district type='härad'>Albo hd<\/district><region type='landskap'>Skåne<\/region><\/location>/
    end

    it "for real!" do
      klagshamn = loadparagraph '3018-klagshamn'
      form = solig.unword(klagshamn)
      expect(form.to_s).to be =~ /<div xml:id='Klagshamn' type='\?'><head><placeName>Klagshamn<\/placeName><\/head> <p><span type='locale'>samhälle<\/span>, <location><district type='socken'>Västra Klagstorps<\/district><district type='socken'>Tygelsjö snr<\/district><district type='härad'>Oxie hd<\/district><region type='landskap'>Skåne<\/region><\/location>/
    end

    it "handles two landskap?"
    it "processes the entry for Norberg"
    it "processes the entry for Bålsta (kn och hd osv.)"

    it "processes entries with f. d." do
      ultuna = loadparagraph '5841-ultuna'
      expected = "<div xml:id='Ultuna' type='?'><head><placeName>Ultuna</placeName></head> <p><span type='locale'>Sveriges lantbruksuniversitet</span>, <span type='locale'>f.d. gods</span>, <location><settlement type='stad'>Uppsala stad</settlement><region type='landskap'>Uppland</region></location>. (<span type='kursiv'>in</span>) <span type='kursiv'>villa Wlertune</span> 1221. – Namnet innehåller genitiv av gudanamnet <span type='kursiv'>Ull</span> och → <span type='kursiv'>tuna</span>. Gudanamnet ingår också i häradsnamnet <span type='kursiv'>Ulleråkers härad</span>. Relationen mellan de båda namnen är omdiskuterad. Se vidare → <span type='kursiv'>Ulleråkers härad</span>.</p></div>"
      actual = solig.unword(ultuna).to_s
      expect(actual).to eq expected
    end

    it "works on Ulva Kvarn" do
      ulva_kvarn = loadparagraph '5842-ulva-kvarn'
      expected = "<div xml:id='Ulva_kvarn' type='?'><head><placeName>Ulva kvarn</placeName></head> <p><span type='locale'>hantverksby</span>, <span type='locale'>f.d. kvarn</span>, <location><settlement type='stad'>Uppsala stad</settlement><region type='landskap'>Uppland</region></location>. <span type='kursiv'>molendino</span> [’kvarnen’] (<span type='kursiv'>in</span>) <span type='kursiv'>Vlfawadh</span> 1344. – Namnet är sammansatt av genitiv pluralis av djurbeteckningen <span type='kursiv'>ulv</span> ’varg’ och <span type='kursiv'>vad</span>. Kvarnen är byggd vid ett gammalt vadställe. Djurbeteckningar är inte ovanliga i namn på -<span type='kursiv'>vad</span>. I detta fall bör förleden ha syftat på vargar som lurade på byte vid vadet.</p></div>"
      actual = solig.unword(ulva_kvarn).to_s
      expect(actual).to eq expected
    end

    it "processes entries with longer strings such as the one for Kattegatt"

    it "stops at the first full stop" do
      abbekås = loadparagraph '444-abbekås'
      form = solig.unword(abbekås)
      actual = form.to_s
      expected = "<div xml:id='Abbekås' type='?'><head><placeName>Abbekås</placeName></head> <p><span type='locale'>tätort</span>, <location><district type='socken'>Skivarps sn</district><district type='härad'>Vemmenhögs hd</district><region type='landskap'>Skåne</region></location>. <span type='kursiv'>Abbekassz</span> 1536. – Namnet på detta gamla fiskeläge innehåller troligen mansnamnet fda. <span type='kursiv'>Abbi</span>. Efterleden är dialektordet <span type='kursiv'>kås</span> ’båtplats, mindre hamn’.</p></div>"
      expect(actual).to eq expected
    end

    it "calls a city a settlement" do
      abborrberget = loadparagraph '445-abborrberget'
      formatted = solig.unword abborrberget
      pending "This is just bizarre.  Strä[new element]ngnäs"
      # byebug
      expect(formatted.to_s).to be =~ /<div><head><placeName>Abborrberget<\/placeName><\/head> <p><span type='locale'>tätort<\/span>, <location><settlement type='stad'>Strängnäs stad<\/settlement><region type='landskap'>Södermanland<\/region><\/location>/ # FIXME Allow non-landskap areas as last entries!
    end

    it "works on an entry with an arrow" do
      lillbäls = loadparagraph '3431-lillbäls'
      expected = "<div xml:id='Lillbäls' type='?'><head><placeName>Lillbäls</placeName></head> <p><span type='locale'>gd</span>, <location><district type='socken'>Bäls sn</district><region type='landskap'>Gotland</region></location> → <span type='kursiv'>Bäl</span>.</p></div>"
      actual = solig.unword(lillbäls).to_s
      expect(actual).to eq expected
    end

    it "doesn’t screw up on arrows" do
      ajmunds = loadparagraph '462-ajmunds'
      beljuset = solig.unword(ajmunds)
      expect(beljuset.to_s).to eq "<div xml:id='Ajmunds' type='?'><head><placeName>Ajmunds</placeName></head> <p><span type='locale'>gårdnamn</span>, <location><region type='landskap'>Gotland</region></location> → <span type='kursiv'>Smiss</span>.</p></div>"
    end

    it "works on entry 459" do
      áhkká = loadparagraph '459-áhkká'
      pending "wip"
      expected = "<div><head><placeName>Áhkká</placeName></head> <p><span type='locale'>fjällmassiv i Stora Sjöfallets nationalpark</span>, <location><district type='socken'>Jokkmokks sn</district></region type='landskap'>Lappland</region></location>. – Det lulesamiska nammet (med äldre stavning <span type='kursiv'>Akka</span>) innehåller ett ornamnselement som förekommer i många berg- och sjönamn i Lule lappmark och som betyder ’(samisk) gudinna; gumma; hustru’. Ordet ingår även i kvinnliga gudabeteckningar. Många av <span type='kursiv'>Áhkká</span>-namnen kan knytas till samernas forntida kult.</p></div>"
      actual = solig.unword(áhkká).to_s
      # byebug
      expect(actual).to eq expected
    end

    it "works on entry 460" do
      áhkájávrre = loadparagraph '460-áhkájávrre'
      actual = solig.unword(áhkájávrre).to_s
      expected = "<div xml:id='Áhkájávrre' type='?'><head><placeName>Áhkájávrre</placeName></head> <p><span type='locale'>vattenregleringsmagasin i Stora Luleälven</span>, <location><district type='socken'>Jokkmokks sn</district><region type='landskap'>Lappland</region></location>. – Namnet (med försvenskad stavning <span type='kursiv'>Akkajaure</span>) är givet efter fjället → <span type='kursiv'>Áhkká</span>. Förleden är genitiv singularis av fjällmassivets namn; efterleden är <span type='kursiv'>jávrre</span> ’sjö’. Namnet har tillkommit efter regleringen av sjösystemet under 1900-talet.</p></div>"
      # byebug
      expect(actual).to eq expected
    end

    it "works on entry 465" do
      akkats = loadparagraph '465-akkats'
      expected = "<div xml:id='Akkats' type='?'><head><placeName>Akkats</placeName></head> <p><span type='locale'>kraftstation i Lilla Luleälven</span>, <location><district type='socken'>Jokkmokks sn</district><region type='landskap'>Lappland</region></location>. – Namnet är bildat till <span type='kursiv'>Akkatsfallen</span>, namn på ett på platsen tidigare befintligt vattenfallskomplex, bestående av tre fall. Fallets namn är en försvenskning av lulesam. <span type='kursiv'>Áhkásjgårttje</span>, sammansatt av <span type='kursiv'>áhkásj</span>, en diminutivform av <span type='kursiv'>áhkká</span> ’(samisk) gudinna; gumma; hustru’ (jfr → <span type='kursiv'>Áhkká</span>), med obekant syftning, och <span type='kursiv'>gårttje</span> ’vattenfall’. Kraftstationens samiska namn är <span type='kursiv'>Áhkásj</span>.</p></div>"
      actual = solig.unword(akkats).to_s
      expect(actual).to eq expected
    end

    it "works on entry 474" do
      albano = loadparagraph '474-albano'
      expected = "<div xml:id='Albano' type='?'><head><placeName>Albano</placeName></head> <p><span type='locale'>område på Norra Djurgården</span>, <location><settlement type='stad'>Stockholms stad</settlement></location> → <span type='kursiv'>Frescati</span>.</p></div>"
      actual = solig.unword(albano).to_s
      # byebug
      expect(actual).to eq expected
    end

    it "works on entry 3383" do
      letsi = loadparagraph '3383-letsi'
      expected = "<div><head><placeName>Letsi</placeName></head> <p><span type='locale'>vattenkraftverk i Lilla Luleälven<span>, <location><district type='socken'>Jokkmokks sn</district><region type='landskap'>Lappland</region></location>. – Namnet är en försvenskning av lulesam. <span type='kursiv'>Liehtse</span>, som var namnet på forsen före utbyggnaden. Ordet <span type='kursiv'>liehtse</span> betyder ’dåligt väder (dimma, duggregn)’ och syftar antagligen på att forsen orsakade dimma om vintern.</p></div>"
      actual = solig.unword(letsi).to_s
      pending "wip"
      # byebug
      expect(actual).to eq expected
    end

    it "replaces the Unicode spaces" do
      lilla_tjärby = loadparagraph '3426-lilla-tjärby'
      formatted = solig.unword(lilla_tjärby)
      expected = "<div xml:id='Lilla_Tjärby' type='?'><head><placeName>Lilla Tjärby</placeName></head> <p><span type='locale'>tätort</span>, <location><district type='socken'>Laholms sn</district><district type='härad'>Höks hd</district><region type='landskap'>Halland</region></location>. – Tätorten har namn efter en intilliggande by, ursprungligen en del av byn Tjärby i grannsocknen → <span type='kursiv'>Tjärby</span>. Namnet <span type='kursiv'>Lilla Tjärby</span> är belagt från mitten av 1600-talet. </p></div>"
      expect(formatted.to_s).to eq expected
    end

    it "works on an entry with a dot" do
      aitikgruvan = loadparagraph '461-aitikgruvan'
      formatted = solig.unword(aitikgruvan)
      expected = "<div xml:id='Aitikgruvan' type='?'><head><placeName>Aitikgruvan</placeName></head> <p><span type='locale'>gruva</span>, <location><district type='socken'>Gällivare sn</district><region type='landskap'>Lappland</region></location>. – Namnet är givet efter berget <span type='kursiv'>Ájtek(várre)</span>, bildat till lulesam. <span type='kursiv'>ájtte</span> ’förrådsbod, härbre’ och <span type='kursiv'>várre</span> ’berg, fjäll’.</p></div>"
    end

    it "works on the first entry in the lexicon" do # 444 Abbekås
      abbekaas = loadparagraph '444-abbekås'

      formatted = solig.unword(abbekaas)
      expected = "<div xml:id='Abbekås' type='?'><head><placeName>Abbekås</placeName></head> <p><span type='locale'>tätort</span>, <location><district type='socken'>Skivarps sn</district><district type='härad'>Vemmenhögs hd</district><region type='landskap'>Skåne</region></location>. <span type='kursiv'>Abbekassz</span> 1536. – Namnet på detta gamla fiskeläge innehåller troligen mansnamnet fda. <span type='kursiv'>Abbi</span>. Efterleden är dialektordet <span type='kursiv'>kås</span> ’båtplats, mindre hamn’.</p></div>"
      actual = formatted.to_s
      expect(actual).to eq expected
    end

    it "works on an entry with a headword in two parts" do # Oxie härad (element 4299)
      oxie = loadparagraph '4299-oxie'
      expected = "<div xml:id='Oxie_härad' type='?'><head><placeName>Oxie härad</placeName></head> <p><span type='locale'>hd</span>, <location><region type='landskap'>Skåne</region></location>. <span type='kursiv'>Oshøgheret</span> ca 1300. – Häradet har namn efter kyrkbyn i socknen → <span type='kursiv'>Oxie</span>.</p></div>"
      formatted = solig.unword(oxie)
      actual = formatted.to_s
      # byebug
      expect(formatted.to_s).to eq expected
    end

    it "works on the first U entry" do
      ucklum = loadparagraph '5813-ucklum'

      formatted = solig.unword(ucklum)
      expected = "<div xml:id='Ucklum' type='?'><head><placeName>Ucklum</placeName></head> <p><span type='locale'>sn</span>, <span type='locale'>tätort</span>, <location><district type='härad'>Inlands Nordre hd</district><region type='landskap'>Bohuslän</region></location>. <span type='kursiv'>Auklanda kirkia</span> 1388. – Socknen har fått sitt namn efter kyrkbyn (numera tätort). Det kan vara identiskt med det från sydvästra Norge kända <span type='kursiv'>Aukland</span>, som har antagits innehålla ett ord med betydelsen ’ökat eller tillfogat land, nyodling’. Det är här i så fall fråga om en mycket tidig nyodling till byn Grössby.</p></div>"
      actual = formatted.to_s
      # byebug
      expect(actual).to eq expected
    end

    it "works on Ume lappmark" do
      ume_lappmark = loadparagraph '5848-ume-lappmark'
      pending "Maybe later"
      expected = "<div xml:id='Ume_lappmark' type='?'><head><placeName>Ume lappmark</placeName></head> <p><span type='locale'>del av Lappland</span>. – Namnet är ursprungligen en historisk-administrativ benämning på samebygden som handels- och beskattningsområde. Det är givet efter huvudorten → <span type='kursiv'>Umeå</span> i Västerbotten.</p></div>"
      actual = solig.unword(ume_lappmark).to_s
      # byebug
      expect(actual).to eq expected
      pending "Maybe even later"
      expect(actual).to eq "<div xml:id='Ume_lappmark' type='?'><head><placeName>Ume lappmark</placeName></head> <p><span type='locale'>del av</span><location><region type='landskap'>Lappland</region></location>. – Namnet är ursprungligen en historisk-administrativ benämning på samebygden som handels- och beskattningsområde. Det är givet efter huvudorten → <span type='kursiv'>Umeå</span> i Västerbotten.</p></div>"
    end
  end

  it "doesn’t crash on Undersåker" do
    undersåker = loadparagraph '5855-undersåker'
    expect { solig.unword(undersåker) }.not_to raise_error
  end

  it "works on the last V entry" # 6344

  it "doesn’t crash on Västra Klagstorp" do # 6308
    västra_klagstorp = loadparagraph '6308-västra-klagstorp'
    expect { solig.unword västra_klagstorp }.to_not raise_error # Raised TypeError (at some point)
  end

  it "works on Ullvi" do # 5834
    ullvi = loadparagraph '5834-ullvi'
    expected = "<div xml:id='Ullvi' type='?'><head><placeName>Ullvi</placeName></head> <p><span type='locale'>gd</span>, <location><district type='socken'>Irsta sn</district><district type='härad'>Siende hd</district><region type='landskap'>Västmanland</region></location>. (<span type='kursiv'>in</span>) <span type='kursiv'>Vllaui</span> 1371. – Namnets förled innehåller gudanamnet <span type='kursiv'>Ull</span> och dess efterled → <span type='kursiv'>vi</span> ’helig plats, kultplats’. Namnet <span type='kursiv'>Ullvi</span> bars tidigare också av den unga tätorten → <span type='kursiv'>Irsta</span> strax norr om gården.</p></div>"
    formatted = solig.unword(ullvi)
    actual = formatted.to_s
    expect(actual).to eq expected
  end

  it "works on Ulrika" do # 5837
    ulrika = loadparagraph '5837-ulrika'
    expected = "<div xml:id='Ulrika' type='?'><head><placeName>Ulrika</placeName></head> <p><span type='locale'>sn</span>, <span type='locale'>tätort</span>, <location><district type='härad'>Valkebo hd</district><region type='landskap'>Östergötland</region></location>. – Socknen bildades 1736 av områden från flera äldre socknar. Namnet gavs för att hedra Ulrika Eleonora. Tätorten har vuxit fram i anslutning till sockenkyrkan.</p></div>"
    actual = solig.unword(ulrika).to_s
    # pending "Later"
    # byebug
    expect(actual).to eq expected
  end

  it "doesn’t tag Småland and Östergötland as invalid" do
    valdemarsvik = loadparagraph '5913-valdemarsvik'
    expect(solig.unword(valdemarsvik).to_s).to be =~ /<region type='landskap'>Småland<\/region>/
  end

  it "outputs the id" do
    w = REXML::XPath.first(REXML::Document.new("<w:document xmlns:w=''><w:p><w:r><w:rPr><w:b /></w:rPr><w:t>Ingelstad</w:t></w:r><w:r><w:t> </w:t></w:r><w:r><w:t>tätort, Östra Torsås sn, Konga hd, Småland</w:t></w:r></w:p></w:document>"), '/w:document/w:p')
    expected = "<div xml:id='Ingelstad' type='?'><head><placeName>Ingelstad</placeName></head> <p><span type='locale'>tätort</span>, <location><district type='socken'>Östra Torsås sn</district><district type='härad'>Konga hd</district><region type='landskap'>Småland</region></location></p></div>"
    actual = solig.unword(w).to_s
    # byebug
    expect(actual).to eq expected
  end

  it "escapes id’s properly" do
    w = REXML::XPath.first(REXML::Document.new("<w:document xmlns:w=''><w:p><w:r><w:rPr><w:b /></w:rPr><w:t>Mellby, Norra, Södra</w:t></w:r><w:r><w:t> </w:t></w:r><w:r><w:t>snr, Kållands hd, Västergötland</w:t></w:r></w:p></w:document>"), '/w:document/w:p')
    expected = "<div xml:id='Mellby._Norra._Södra' type='?'><head><placeName>Mellby, Norra, Södra</placeName></head> <p><span type='locale'>snr</span>, <location><district type='härad'>Kållands hd</district><region type='landskap'>Västergötland</region></location></p></div>"
    actual = solig.unword(w).to_s
    expect(actual).to eq expected
  end

  it "adds an empty bebyggelsenamn" do
    w = REXML::XPath.first(REXML::Document.new("<w:document xmlns:w=''><w:p><w:r><w:rPr><w:b /></w:rPr><w:t>Kattorp</w:t></w:r><w:r><w:t> </w:t></w:r><w:r><w:t>sn, tätort, Luggude hd, Skåne</w:t></w:r></w:p></w:document>"), '/w:document/w:p')
    expected = "<div xml:id='Kattorp' type='?'><head><placeName>Kattorp</placeName></head> <p><span type='locale'>sn</span>, <span type='locale'>tätort</span>, <location><district type='härad'>Luggude hd</district><region type='landskap'>Skåne</region></location></p></div>"
    actual = solig.unword(w).to_s
    expect(actual).to eq expected
  end
end
