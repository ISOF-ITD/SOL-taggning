require 'spec_helper'

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
end

describe REXML::Element do
  describe '#add_italic_text' do
    it "adds italic text" do
      foo = REXML::Document.new('<doc>foo</doc>').root

      foo.add_text ' '
      foo.add_italic_text 'bar'
      foo.add_text ' quux'

      expect(foo.to_s).to eq "<doc>foo <span style='italic'>bar</span> quux</doc>"
    end

    it "calls #add_escaped_text" do
      doc = REXML::Document.new('<doc>content</doc>')
      expect(doc.root).to receive(:add_escaped_text).with('a \fd b')
      doc.root.add_escaped_text('a \fd b')
    end
  end

  describe '#escape_text' do
    it "escapes the text" do
      doc = REXML::Document.new('<doc>x \\fd y</doc>')
      doc.root.escape_text!
      expect(doc.root
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
  end

  describe '#add_escaped_text' do
    it "interprets the escape sequences" do
      doc = REXML::Document.new "<doc><p></p></doc>"
      element = doc.root.elements.first
      element.add_escaped_text "foo \\fd bar"
      expect(element.text).to eq "foo f.d. bar"
    end
  end
end

describe Solig do
  let(:solig) { Solig.new }

  describe '.escape' do
    it "replaces “f.d.” with \\fd" do
      expect(Solig.escape('lantbruksuniversitet, f.d. gods')).to eq 'lantbruksuniversitet, \fd gods'
    end
  end

  describe '#unword' do
    it "dismantles the Word XML structure" do
      bro = loadparagraph '1023-bro'
      pending "This is going to be painful"
      expect(solig.unword(bro).to_s).to eq "<div><head><placeName>Bro</placeName></head> <p><span type='locale'>sn</span>, <location><district type='skeppslag'>Bro och Vätö skg</district><region type='landskap'>Uppland</region></location> → <span style='italic'>Roslags-Bro</span>.</p></div>"
    end

    it "processes a parish without a härad" do
      husby = loadparagraph '2498-husby'
      form = solig.unword(husby)
      expect(form.to_s).to be =~ /^<div><head><placeName>Husby<\/placeName><\/head> <p><span type='locale'>sn<\/span>, <span type='locale'>tätort<\/span>, <location><region type='landskap'>Dalarna<\/region><\/location>/
    end

    it "processes a parish with an extra locale" do
      hurva = loadparagraph '2490-hurva'
      form = solig.unword(hurva)
      expect(form.to_s).to be =~ /^<div><head><placeName>Hurva<\/placeName><\/head> <p><span type='locale'>sn<\/span>, <span type='locale'>tätort<\/span>, <location><district type='härad'>Frosta hd<\/district><region type='landskap'>Skåne<\/region><\/location>/
    end

    it "processes a point with an extra locale" do
      vätteryd = loadparagraph '6338-vätteryd'
      form = solig.unword(vätteryd)
      expect(form.to_s).to be =~ /^<div><head><placeName>Vätteryd<\/placeName><\/head> <p><span type='locale'>torp<\/span>, <span type='locale'>gravfält<\/span>, <location><district type='socken'>Norra Mellby sn<\/district><district type='härad'>Västra Göinge hd<\/district><region type='landskap'>Skåne<\/region><\/location>/
    end

    it "processes a parish with a compound name" do
      västra_vram = loadparagraph '6331-västra-vram'
      form = solig.unword(västra_vram)
      expect(form.to_s).to be =~ /^<div><head><placeName>Västra Vram<\/placeName><\/head> <p><span type='locale'>sn<\/span>, <location><district type='härad'>Gärds hd<\/district><region type='landskap'>Skåne<\/region><\/location>/
    end

    it "processes a simple parish" do
      västrum = loadparagraph '6333-västrum'
      form = solig.unword(västrum)
      expect(form.to_s).to be =~ /<div><head><placeName>Västrum<\/placeName><\/head> <p><span type='locale'>sn<\/span>, <location><district type='härad'>Södra Tjusts hd<\/district><region type='landskap'>Småland<\/region><\/location>/
    end

    it "handles the case of two härad" do
      kinnekulle = loadparagraph '3006-kinnekulle'
      form = solig.unword(kinnekulle)
      expect(form.to_s).to be =~ /^<div><head><placeName>Kinnekulle<\/placeName><\/head> <p><span type='locale'>berg<\/span>, <location><district type='härad'>Kinne<\/district><district type='härad'>Kinnefjärdings hd<\/district><region type='landskap'>Västergötland<\/region><\/location>/
    end

    it "handles the case of two socknar" do
      kivik = loadparagraph '3015-kivik'
      form = solig.unword(kivik)
      expect(form.to_s).to be =~ /<div><head><placeName>Kivik<\/placeName><\/head> <p><span type='locale'>tätort<\/span>, <location><district type='socken'>Södra Mellby<\/district><district type='socken'>Vitaby snr<\/district><district type='härad'>Albo hd<\/district><region type='landskap'>Skåne<\/region><\/location>/
    end

    it "for real!" do
      klagshamn = loadparagraph '3018-klagshamn'
      form = solig.unword(klagshamn)
      expect(form.to_s).to be =~ /<div><head><placeName>Klagshamn<\/placeName><\/head> <p><span type='locale'>samhälle<\/span>, <location><district type='socken'>Västra Klagstorps<\/district><district type='socken'>Tygelsjö snr<\/district><district type='härad'>Oxie hd<\/district><region type='landskap'>Skåne<\/region><\/location>/
    end

    it "handles two landskap?"
    it "processes the entry for Norberg"
    it "processes the entry for Bålsta (kn och hd osv.)"

    it "processes entries with f. d." do
      ultuna = loadparagraph '5841-ultuna'
      expected = "<div><head><placeName>Ultuna</placeName></head> <p><span type='locale'>Sveriges lantbruksuniversitet</span>, <span type='locale'>f.d. gods</span>, <location><region type='landskap'>Uppland</region></location>. (<span style='italic'>in</span>) <span style='italic'>villa Wlertune</span> 1221. – Namnet innehåller genitiv av gudanamnet <span style='italic'>Ull<span> och → <span style='italic'>tuna</span>. Gudanamnet ingår också i häradsnamnet <span style='italic'>Ulleråkers härad</span>. Relationen mellan de båda namnen är omdiskuterad. Se vidare → <span style='italic'>Ulleråkers härad</span>.</p></div>"
      actual = solig.unword(ultuna).to_s
      expect(actual).to eq expected
    end

    it "works on Ulva Kvarn" do
      ulva_kvarn = loadparagraph '5842-ulva-kvarn'
      expected = "<div><head><placeName>Ulva kvarn</placeName></head> <p><span type='locale'>hantverksby</span>, <span type='locale'>f.d. kvarn</span>, <location><settlement type='stad'>Uppsala stad</settlement><region type='landskap'>Uppland</region></location>. <span style='italic'>molendino</span> [’kvarnen’] (<span style='italic'>in</span>) <span style='italic'>Vlfawadh</span> 1344. – Namnet är sammansatt av genitiv pluralis av djurbeteckningen <span style='italic'>ulv</span> ’varg’ och <span style='italic'>vad</span>. Kvarnen är byggd vid ett gammalt vadställe. Djurbeteckningar är inte ovanliga i namn på <span style='italic'>-vad</span>. I detta fall bör förleden ha syftat på vargar som lurade på byte vid vadet.</p></div>"
      actual = solig.unword(ulva_kvarn).to_s
      expect(actual).to eq expected
    end

    it "processes entries with longer strings such as the one for Kattegatt"

    it "stops at the first full stop" do
      abbekås = loadparagraph '444-abbekås'
      form = solig.unword(abbekås)
      actual = form.to_s
      expected = "<div><head><placeName>Abbekås</placeName></head> <p><span type='locale'>tätort</span>, <location><district type='socken'>Skivarps sn</district><district type='härad'>Vemmenhögs hd</district><region type='landskap'>Skåne</region></location>. <span style='italic'>Abbekassz</span> 1536. – Namnet på detta gamla fiskeläge innehåller troligen mansnamnet fda. <span style='italic'>Abbi</span>. Efterleden är dialektordet <span style='italic'>kås</span> ’båtplats, mindre hamn’.</p></div>"
      # byebug
      expect(actual).to eq expected
    end

    it "calls a city a settlement" do
      abborrberget = loadparagraph '445-abborrberget'
      formatted = solig.unword abborrberget
      pending "This is just bizarre.  Strä[new element]ngnäs"
      expect(formatted.to_s).to be =~ /<div><head><placeName>Abborrberget<\/placeName><\/head> <p><span type='locale'>tätort<\/span>, <location><settlement type='stad'>Strängnäs stad<\/settlement><region type='landskap'>Södermanland<\/region><\/location>/ # FIXME Allow non-landskap areas as last entries!
    end

    it "works on an entry with an arrow" do
      lillbäls = loadparagraph '3431-lillbäls'
      expected = "<div><head><placeName>Lillbäls</placeName></head> <p><span type='locale'>gd</span>, <location><district type='socken'>Bäls sn</district><region type='landskap'>Gotland</region></location> → <span style='italic'>Bäl</span>.</p></div>"
      actual = solig.unword(lillbäls).to_s
      expect(actual).to eq expected
    end

    it "doesn’t screw up on arrows" do
      ajmunds = loadparagraph '462-ajmunds'
      beljuset = solig.unword(ajmunds)
      expect(beljuset.to_s).to eq "<div><head><placeName>Ajmunds</placeName></head> <p><span type='locale'>gårdnamn</span>, <location><region type='landskap'>Gotland</region></location> → <span style='italic'>Smiss</span>.</p></div>"
    end

    it "works on entry 459" do
      áhkká = loadparagraph '459-áhkká'
      pending "wip"
      expect(solig.unword(áhkká).to_s).to eq "<div><head><placeName>Áhkká<placeName></head> <p><span type='locale'>fjällmassiv i Stora Sjöfallets nationalpark, <location><district type='socken'>Jokkmokks sn</district></region type='landskap'>Lappland</region></location>. – Det lulesamiska nammet (med äldre stavning <span style='italic'>Akka</span>) innehåller ett ornamnselement som förekommer i många berg- och sjönamn i Lule lappmark och som betyder ’(samisk) gudinna; gumma; hustru’. Ordet ingår även i kvinnliga gudabeteckningar. Många av <span style='italic'>Áhkká</span>-namnen kan knytas till samernas forntida kult.</p></div>"
    end

    it "works on entry 460" do
      áhkájávrre = loadparagraph '460-áhkájávrre'
      pending "wip"
      expect(solig.unword(áhkájávrre).to_s).to eq "<div><head><placeName>Áhkájávrre</placeName></head> <p><span type='locale'>vattenregleringsmagasin i Store Luleälven</span>, <location><district type='socken'>Jokkmokks sn</district><region type='landskap'>Lappland</region></location>. – Namnet (med försvenskad stavning <span style='italic'>Akkajaure</span>) är givet efter fjället → <span syle='italic'>Áhkká</span>. Förleden är genitiv singularis av fjällmaassivets namn; efterleden är <span style='italic'>jávrre</span> ’sjö’. Namnet har tillkommit efter regleringen av sjösystemet under 1900-talet.</p></div>"
    end

    it "works on entry 465" do
      akkats = loadparagraph '465-akkats'
      pending "wip"
      expect(solig.unword(akkats).to_s).to eq "<div><head><placeName>Akkats</placeName></head> <p><span type='locale'>kraftstation i Lilla Luleälven</span>, <location><district type='socken'>Jokkmokks sn</district><region type='landskap'>Lappland</region></location>. – Namnet är bildat till <span style='italic'>Akkatsfallen</span>, namn på ett på platsen tidigare befintligt vattenfallskomplex, bestående av tre fall. Fallets namn är en försvenskning av lulesam. <span style='italic'>Áhkásjgårttje</span>, sammansatt av <span type='italic'>áhkásj</span>, en diminutivform av <span style='italic'>áhkká</span> ’(samisk) gudinna; gumma; hustru’ (jfr. → <span style='italic'>Áhkká</span>), med obekant syftning, och <span style='italic'>gårttje</span> ’vattenfall’. Kraftstationens samiska namn är <span style='italic'>Áhkásj</span>.</p></div>"
    end

    it "works on entry 474" do
      albano = loadparagraph '474-albano'
      pending "wip"
      expect(solig.unword(albano).to_s).to eq "<div><head><placeName>Albano</placeName></head> <p><span type='locale'>område på Norra Djurgården</span>, <location><settlement type='stad'>Stockholms stad</settlement></location> → <span style='italic'>Frescati</span>.</p></div>"
    end

    it "works on entry 3383" do
      letsi = loadparagraph '3383-letsi'
      expected = "<div><head><placeName>Letsi</placeName></head> <p><span type='locale'>vattenkraftverk i Lilla Luleälven<span>, <location><district type='socken'>Jokkmokks sn</district><region type='landskap'>Lappland</region></location>. – Namnet är en försvenskning av lulesam. <span style='italic'>Liehtse</span>, som var namnet på forsen före utbyggnaden. Ordet <span style='italic'>liehtse</span> betyder ’dåligt väder (dimma, duggregn)’ och syftar antagligen på att forsen orsakade dimma om vintern.</p></div>"
      actual = solig.unword(letsi).to_s
      # byebug
      pending "wip"
      expect(actual).to eq expected
    end

    it "replaces the Unicode spaces" do
      lilla_tjärby = loadparagraph '3426-lilla-tjärby'
      formatted = solig.unword(lilla_tjärby)
      expected = "<div><head><placeName>Lilla Tjärby</placeName></head> <p><span type='locale'>tätort</span>, <location><district type='socken'>Laholms sn</district><district type='härad'>Höks hd</district><region type='landskap'>Halland</region></location>. – Tätorten har namn efter en intilliggande by, ursprungligen en del av byn Tjärby i grannsocknen → <span style='italic'>Tjärby</span>. Namnet <span style='italic'>Lilla Tjärby</span> är belagt från mitten av 1600-talet. </p></div>"
      expect(formatted.to_s).to eq expected
    end

    it "works on an entry with a dot" do
      aitikgruvan = loadparagraph '461-aitikgruvan'
      formatted = solig.unword(aitikgruvan)
      expected = "<div><head><placeName>Aitikgruvan</placeName></head> <p><span type='locale'>gruva</span>, <location><district type='socken'>Gällivare sn</district><region type='landskap'>Lappland</region></location>. – Namnet är givet efter berget <span style='italic'>Ájtek(várre)</span>, bildat till lulesam. <span style='italic'>ájtte</span> ’förrådsbod, härbre’ och <span style='italic'>várre</span> ’berg, fjäll’.</p></div>"
    end

    it "works on the first entry in the lexicon" do # 444 Abbekås
      abbekaas = loadparagraph '444-abbekås'

      formatted = solig.unword(abbekaas)
      expected = "<div><head><placeName>Abbekås</placeName></head> <p><span type='locale'>tätort</span>, <location><district type='socken'>Skivarps sn</district><district type='härad'>Vemmenhögs hd</district><region type='landskap'>Skåne</region></location>. <span style='italic'>Abbekassz</span> 1536. – Namnet på detta gamla fiskeläge innehåller troligen mansnamnet fda. <span style='italic'>Abbi</span>. Efterleden är dialektordet <span style='italic'>kås</span> ’båtplats, mindre hamn’.</p></div>"
      actual = formatted.to_s
      expect(actual).to eq expected
    end

    it "works on an entry with a headword in two parts" do # Oxie härad (element 4299)
      oxie = loadparagraph '4299-oxie'
      formatted = solig.unword(oxie)
      expect(formatted.to_s).to eq "<div><head><placeName>Oxie härad</placeName></head> <p><span type='locale'>hd</span>, <location><region type='landskap'>Skåne</region></location>. <span style='italic'>Oshøgheret</span> ca 1300. – Häradet har namn efter kyrkbyn i socknen → <span style='italic'>Oxie</span>.</p></div>"
    end

    it "works on the first U entry" do
      ucklum = loadparagraph '5813-ucklum'

      formatted = solig.unword(ucklum)
      expect(formatted.to_s).to eq "<div><head><placeName>Ucklum</placeName></head> <p><span type='locale'>sn</span>, <span type='locale'>tätort</span>, <location><district type='härad'>Inlands Nordre hd</district><region type='landskap'>Bohuslän</region></location>. <span style='italic'>Auklanda kirkia</span> 1388. – Socknen har fått sitt namn efter kyrkbyn (numera tätort). Det kan vara identiskt med det från sydvästra Norge kända <span style='italic'>Aukland</span>, som har antagits innehålla ett ord med betydelsen ’ökat eller tillfogat land, nyodling’. Det är här i så fall fråga om en mycket tidig nyodling till byn Grössby.</p></div>"
    end
  end

  it "works on the last V entry" # 6344

  it "doesn’t crash on Västra Klagstorp" do # 6308
    västra_klagstorp = loadparagraph '6308-västra-klagstorp'
    expect { solig.unword västra_klagstorp }.to_not raise_error TypeError
  end

  it "works on Ullvi" do # 5834
    ullvi = loadparagraph '5834-ullvi'
    expected = "<div><head><placeName>Ullvi</placeName></head> <p><span type='locale'>gd</span>, <location><district type='socken'>Irsta sn</district><district type='härad'>Siende hd</district><region type='landskap'>Västmanland</region></location>. (<span style='italic'>in</span>) <span style='italic'>Vllaui</span> 1371. – Namnets förled innehåller gudanamnet <span style='italic'>Ull</span> och dess efterled → <span style='italic'>vi</span> ’helig plats, kultplats’. Namnet <span style='italic'>Ullvi</span> bars tidigare också av den unga tätorten → <span style='italic'>Irsta</span> strax norr om gården.</p></div>"
    formatted = solig.unword(ullvi)
    actual = formatted.to_s
    expect(actual).to eq expected
  end

  it "works on Ulrika" do # 5837
    ulrika = loadparagraph '5837-ulrika'
    expected = "<div><head><placeName>Ulrika</placeName></head> <p><span type='locale'>sn</span>, <span type='locale'>tätort</span>, <location><district type='härad'>Valkebo hd</district><region type='landskap'>Östergötland</region></location>. – Socknen bildades 1736 av områden från flera äldre socknar. Namnet gavs för att hedra Ulrika Eleonora. Tätorten har vuxit fram i anslutning till sockenkyrkan.</p></div>"
    actual = solig.unword(ulrika).to_s
    # pending "Later"
    # byebug
    expect(actual).to eq expected
  end
end
