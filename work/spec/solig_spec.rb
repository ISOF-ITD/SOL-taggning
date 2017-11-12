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

  describe '#is_one_word?' do
    it "doesn’t crash on a nil input" do
      expect { nil.is_one_word? }.not_to raise_error
    end

    it "returns false" do
      expect(nil.is_one_word?).to be_falsey
    end
  end

  describe '#is_locale?' do
    it "doesn’t crash" do
      expect { nil.is_locale? }.not_to raise_error
    end

    it "returns false" do
      expect(nil.is_locale?).to be_falsey
    end
  end

  describe '#wtext' do
    it "returns the empty string" do
      expect(nil.wtext).to eq ''
    end
  end
end

describe Hash do
  describe '#reverse' do
    it "reverses the hash" do
      expect({ a: 1, b: 2, c: 3 }.reverse).to eq({ 1 => :a, 2 => :b, 3 => :c })
    end
  end
end

describe String do
  let(:ox) { "Oxie härad " } # With trailing U+2003 EM SPACE and U+2005 FOUR-PER-EM SPACE in the middle

  describe '#ustrip' do
    it "strips all Unicode space characters" do
      expect(ox.ustrip).to eq "Oxie härad"
    end

    it "even strips out ASCII characters" do
      expect("Väne härad ".ustrip).to eq "Väne härad"
    end
  end

  describe '#uspace' do
    it "replaces all Unicode space characters" do
      expect(ox.uspace).to eq "Oxie härad "
    end

    it "replaces U+2002 EN SPACE" do
      expect('a b'.uspace).to eq 'a b'
    end
  end

  describe '#is_one_word?' do
    it "returns true if string is one word" do
      expect('foo'.is_one_word?).to be_truthy
    end

    it "returns false if not" do
      expect('foo bar'.is_one_word?).to be_falsey
    end

    it "strips the input first" do
      expect(' foo '.is_one_word?).to be_truthy
    end
  end

  describe '#is_locale?' do
    it "returns true on single words" do
      expect('foo'.is_locale?).to be_truthy
    end

    it "returns false on multiple words" do
      expect('foo bar'.is_locale?).to be_falsey
    end

    it "returns true on strings that contain \\fd" do
      expect('\\fd sn'.is_locale?).to be_truthy
    end

    it "returns false on names of landskap" do
      expect('Västmanland'.is_locale?).to be_falsey
    end

    it "strips names of landskap before checking them" do
      expect(' Dalarna'.is_locale?).to be_falsey
    end

    it "calls Solig.is_locale?" do
      expect(Solig).to receive(:is_locale?).with('by')
      'by'.is_locale?
    end
  end

  describe '#is_landskap?' do
    it "calls Solig.is_landskap?" do
      expect(Solig).to receive(:is_landskap?).with('Södermanland')
      'Södermanland'.is_landskap?
    end
  end
end

describe Element do
  describe '#has_invalid?' do
    it "returns true if element has <invalid> children" do
      doc = Document.new "<doc><p>foo <invalid>nonsense</invalid> bar.</p> <p>Baz quux!</p></doc>"
      element = doc.root
      expect(element.has_invalid?).to be_truthy
    end

    it "returns false otherwise" do
      doc = Document.new "<doc><p>foo <locale>nonsense</locale> bar.</p> <p>Baz quux!</p></doc>"
      element = doc.root
      expect(element.has_invalid?).to be_falsey
    end
  end

  describe '#add_italic_text' do
    it "adds italic text" do
      foo = Document.new('<doc>foo</doc>').root

      foo.add_text ' '
      foo.add_italic_text 'bar'
      foo.add_text ' quux'

      expect(foo.to_s).to eq "<doc>foo <span type='kursiv'>bar</span> quux</doc>"
    end

    it "calls #add_escaped_text" do
      doc = Document.new('<doc>content</doc>')
      expect(doc.root).to receive(:add_escaped_text).with('a \\fd b')
      doc.root.add_escaped_text('a \\fd b')
    end
  end

  describe '#escape_text!' do
    it "escapes the text" do
      doc = Document.new('<doc>x \\fd y</doc>')
      doc.root.escape_text!
      expect(doc.root.text).to eq 'x f.d. y'
    end
  end

  describe '#add_escaped_text' do
    it "calls Solig.add_escaped_text" do
      doc = Document.new('<doc><p>Foo.</p></doc>')
      element = doc.root.elements.first
      expect(Solig).to receive(:add_escaped_text).with(element, '\\fd')
      element.add_escaped_text '\\fd'
    end
  end

  describe '#isitalic?' do
    it "returns true if text bit is italic" do
      doc = Document.new "<w:document xmlns:w='somelink'><w:r><w:rPr><w:i /></w:rPr></w:r></w:document>"
      text = doc.root.elements.first
      expect(text.isitalic?).to be_truthy
    end

    it "returns false otherwise" do
      doc = Document.new "<w:document xmlns:w='ns'><w:r><w:rPr></w:rPr></w:r></w:document>"
      text = doc.root.elements.first
      expect(text.isitalic?).to be_falsey
    end

    it "doesn’t crash if element doesn’t conform to the .docx format" do
      doc = Document.new "<w:document xmlns:w='ns'><w:p></w:p></w:document>"
      text = doc.root.elements.first
      expect { text.isitalic? }.to_not raise_error
    end
  end

  describe '#isbold?' do
    it "returns true if text bit is bold" do
      doc = Document.new "<w:document xmlns:w=''><w:r><w:rPr><w:b /></w:rPr></w:r></w:document>"
      bold = doc.root.elements.first
      expect(bold.isbold?).to be_truthy
    end

    it "returns false otherwise" do
      doc = Document.new "<w:document xmlns:w=''><w:r><w:rPr></w:rPr></w:r></w:document>"
      notbold = doc.root.elements.first
      expect(notbold.isbold?).to be_falsey
    end

    it "doesn’t crash if element doesn’t have an rPr child" do
      doc = Document.new "<w:document xmlns:w=''><w:p></w:p></w:document>"
      not_a_text_bit = doc.root.elements.first
      expect(not_a_text_bit.isbold?).to be_falsey
    end
  end

  describe '#wtext' do
    it "returns the text bit" do
      doc = Document.new "<w:document xmlns:w=''><w:r><w:t>foo</w:t></w:r></w:document>"
      bit = doc.root.elements.first
      expect(bit.wtext).to eq 'foo'
    end

    it "doesn’t crash if element doesn’t contain a text bit" do
      doc = Document.new "<w:document xmlns:w=''><w:p>bar</w:p></w:document>"
      bit = doc.root.elements.first
      expect { bit.wtext }.to_not raise_error
    end

    it "returns nil if element doesn’t contain a text bit" do
      doc = Document.new "<w:document xmlns:w=''><w:p>quux</w:p></w:document>"
      bit = doc.root.elements.first
      expect(bit.wtext).to be_nil
    end

    it "calls Solig.escape" do
      doc = Document.new "<w:document xmlns:w=''><w:p><w:r><w:t>foo \\fd bar</w:t></w:r></w:p></w:document>"
      bit = XPath.first(doc, '/w:document/w:p/w:r')
      expect(Solig).to receive(:escape).with('foo \\fd bar')
      bit.wtext
    end
  end
end

describe Solig do
  let(:solig) { Solig.new }

  describe '#is_landskap?' do
    it "returns true if self is a landskap name" do
      expect('Uppland'.is_landskap?).to be_truthy
    end

    it "returns false otherwise" do
      expect('talgoxe'.is_landskap?).to be_falsey
    end

    it "has an exclusive list of landskap" do
      landskap = Solig.class_variable_get(:@@landskap)
      expect(landskap.count).to eq 25
      expect(landskap[1]).to eq 'Blekinge'
    end
  end

  describe '.landskap_regexp' do
    it "returns the landskap regexp" do
      expect(Solig.landskap_regexp).to be_a Regexp
    end

    it "matches Småland" do
      expect('Småland' =~ Solig.landskap_regexp).to be_truthy
    end

    it "doesn’t match Värend" do
      expect('Värend' =~ Solig.landskap_regexp).to be_falsey
    end

    it "doesn’t match Jönköping" do
      expect('Jönköping' =~ Solig.landskap_regexp).to be_falsey
    end

    it "caches the regexp" do
      Solig.landskap_regexp
      expect(Solig.class_variable_get(:@@landskap_regexp)).not_to be_nil
    end

    it "is not anchored" do
      expect('Småland och Västergötland' =~ Solig.landskap_regexp).to be_truthy
    end

    it "... really not!" do
      expect(' Skåne' =~ Solig.landskap_regexp).to be_truthy
    end
  end# TODO

  describe '#is_locale?' do
    it "returns true on strings starting with “nu”" do
      expect(Solig.is_locale?('nu stadsdel')).to be_truthy
    end

    it "doesn’t return true if “nu” is somewhere else" do # FIXME Find another solution
      expect(Solig.is_locale?('älven Aliseatnu')).to be_falsey
    end

    it "returns true on strings starting with “samt”" do # TODO Fix all that!
      expect(Solig.is_locale?('samt sn')).to be_truthy
    end

    it "returns true on strings starting with “och”" do
      expect(Solig.is_locale?('och tätort')).to be_truthy # FIXME CHeck too
    end
  end

  describe '.escape' do
    it "replaces “f.d.” with \\fd" do
      expect(Solig.escape('lantbruksuniversitet, f.d. gods')).to eq 'lantbruksuniversitet, \\fd gods'
    end

    it "doesn’t crash on nil input" do
      expect { Solig.escape(nil) }.not_to raise_error
    end
  end

  describe '#initialize' do
    it "calls #reset" do
      expect_any_instance_of(Solig).to receive(:reset)
      Solig.new
    end
  end

  describe '#reset' do
    it "resets @state to :initial" do
      solig.reset
      expect(solig.instance_variable_get(:@state)).to eq :initial
    end

    it "resets @carryover to the empty string" do
      solig.reset
      expect(solig.instance_variable_get(:@carryover)).to eq ''
    end

    it "resets @currtext to the empty string" do
      solig.reset
      expect(solig.instance_variable_get(:@currtext)).to eq ''
    end

    it "resets @rs to the empty array " do
      solig.reset
      expect(solig.instance_variable_get(:@rs)).to eq []
    end

    it "resets @r to the empty string" do
      solig.reset
      expect(solig.instance_variable_get(:@r)).to eq ''
    end
  end

  describe '#unword' do
    it "calls #reset" do
      expect(solig).to receive(:reset)
      solig.unword Document.new
    end

    it "dismantles the Word XML structure" do
      bro = loadparagraph '1023-bro'
      # pending "This is going to be painful"
      expected = "<div xml:id='Bro' type='?'><head><placeName>Bro</placeName></head> <p><span type='locale'>sn</span>, <location><district type='skeppslag'>Bro och Vätö skg</district><region type='landskap'>Uppland</region></location> → <span type='kursiv'>Roslags-Bro</span>.</p></div>"
      actual = solig.unword(bro).to_s
      # byebug
      expect(actual).to eq expected
    end

    it "processes a parish without a härad" do
      husby = loadparagraph '2498-husby'
      form = solig.unword(husby)
      expected = /^<div xml:id='Husby' type='\?'><head><placeName>Husby<\/placeName><\/head> <p><span type='locale'>sn<\/span>, <span type='locale'>tätort<\/span>, <location><region type='landskap'>Dalarna<\/region><\/location>/
      actual = form.to_s
      # byebug
      expect(actual).to be =~ expected
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

    it "handles two landskap" do
      kolmården = loadparagraph '3063-kolmården'
      expected = "<div xml:id='Kolmården' type='?'><head><placeName>Kolmården</placeName></head> <p><span type='locale'>skog</span>, <location><region type='landskap'>Södermanland</region><region type='landskap'>Östergötland</region></location>. <span type='kursiv'>Culmard</span> 1303. – Namnet innehåller ett fornsvenskt *<span type='kursiv'>mardher</span> ’grusig mark; stenrik eller blockrik mark; grusig eller stenig skog’ e.d. Förleden <span type='kursiv'>Kol</span>- står snarast för ’mörk, skuggig’ e.d. eller för ’svart, förkolnad (på grund av skogsbrand)’, även om ett samband med kolning inte kan uteslutas. Jfr → <span type='kursiv'>Åmål</span> och → <span type='kursiv'>Ödmården</span>.</p></div>"
      actual = solig.unword(kolmården).to_s
      # byebug
      expect(actual).to eq expected
    end

    it "processes the entry for Norberg" do
      norberg = loadparagraph '4012-norberg'
      expected = "<div xml:id='Norberg' type='?'><head><placeName>Norberg</placeName></head> <p><span type='locale'>kn</span>, <span type='locale'>sn</span>, <span type='locale'>tätort</span>, <location><district type='bergslag'>Gamla Norbergs bergslag</district><region type='landskap'>Västmanland</region></location>. <span type='kursiv'>Norobergh</span> 1303 sen avskr., (<span type='kursiv'>af</span>) <span type='kursiv'>Noraberghe</span> 1367. – Namnet, vars efterled är <span type='kursiv'>berg</span> i en äldre betydelse ’bergslag’ (jfr → <span type='kursiv'>Bergslagen</span>), är ett ursprungligt bygdenamn. Förleden innehåller troligen ett äldre ånamn *<span type='kursiv'>Nora</span> på Norbergsån, sjön Norens avloppså till Trätten. Sjönamnet <span type='kursiv'>Noren</span> i sin tur innehåller <span type='kursiv'>nor</span> ’smalt vattendrag som förenar två vattenpartier’ med syftning på den korta ån mellan Noren och den lilla sjön Kalven. Det sistnämnda namnet, vanligt på flera håll i Sverige, betecknar sjön som den större sjön Norens »kalv». Kommunen Norberg har sitt namn efter socknen. Tätorten har vuxit fram ur bebyggelsen kring kyrkan och kringliggande byar.</p></div>"
      actual = solig.unword(norberg).to_s
      # byebug
      expect(actual).to eq expected
    end

    it "processes the entry for Bålsta (kn och hd osv.)" do
      bålsta = loadparagraph '1135-bålsta'
      expected = "<div xml:id='Bålsta' type='?'><head><placeName>Bålsta</placeName></head> <p><span type='locale'>kn</span>, <span type='locale'>tätort</span>, <location><district type='socken'>Yttergrans</district><district type='socken'>Kalmars snr</district><district type='härad'>Håbo hd</district><region type='landskap'>Uppland</region></location>. (<span type='kursiv'>in</span>) <span type='kursiv'>Bardestum</span> 1316. – Ortnamnet, som äldst avsåg en by i Yttergrans socken, kan i förleden innehålla genitiv av mansnamnet fsv. <span type='kursiv'>Bardhe</span>. Alternativt innehåller förleden fsv. *<span type='kursiv'>bardhe</span> ’kant, rand’, svarande mot det norska dialektordet <span type='kursiv'>bard</span>(<span type='kursiv'>e</span>), syftande på någon terrängformation. Efterleden är → <span type='kursiv'>sta</span>(<span type='kursiv'>d</span>). Tätorten har snarast fått sitt namn efter järnvägsstationen Bålsta på banan Stockholm–Enköping–Västerås, öppnad 1879.</p></div>" # Obs. Stockholm-Enköping-Västerås har U+2013!
      actual = solig.unword(bålsta).to_s
      # byebug
      expect(actual).to eq expected
    end

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

    it "processes entries with longer strings such as the one for Kattegatt" do
      kattegatt = loadparagraph '2955-kattegatt'
      expect(solig.unword(kattegatt).to_s).to be =~ /<div xml:id='Kattegatt' type='\?'><head><placeName>Kattegatt<\/placeName><\/head> <p><span type='locale'>havsområde avgränsat av Jylland och Själland samt svenska västkusten<\/span>\. – Liksom → <span type='kursiv'>Skagerrak<\/span> härrör namnet från 1600-talet och är av holländskt ursprung\./
    end

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
      # pending "This is just bizarre.  Strä[new element]ngnäs"
      # byebug
      expect(formatted.to_s).to be =~ /<div xml:id='Abborrberget' type='\?'><head><placeName>Abborrberget<\/placeName><\/head> <p><span type='locale'>tätort<\/span>, <location><settlement type='stad'>Strängnäs stad<\/settlement><region type='landskap'>Södermanland<\/region><\/location>/ # FIXME Allow non-landskap areas as last entries!
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
      # pending "wip"
      expected = "<div xml:id='Áhkká' type='?'><head><placeName>Áhkká</placeName></head> <p><span type='locale'>fjällmassiv i Stora Sjöfallets nationalpark</span>, <location><district type='socken'>Jokkmokks sn</district><region type='landskap'>Lappland</region></location>. – Det lulesamiska namnet (med äldre stavning <span type='kursiv'>Akka</span>) innehåller ett ortnamnselement som förekommer i många berg- och sjönamn i Lule lappmark och som betyder ’(samisk) gudinna; gumma; hustru’. Ordet ingår även i kvinnliga gudabeteckningar. Många av <span type='kursiv'>Áhkká</span>-namnen kan knytas till samernas forntida kult.</p></div>"
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
      expected = "<div xml:id='Letsi' type='?'><head><placeName>Letsi</placeName></head> <p><span type='locale'>vattenkraftverk i Lilla Luleälven</span>, <location><district type='socken'>Jokkmokks sn</district><region type='landskap'>Lappland</region></location>. – Namnet är en försvenskning av lulesam. <span type='kursiv'>Liehtse</span>, som var namnet på forsen före utbyggnaden. Ordet <span type='kursiv'>liehtse</span> betyder ’dåligt väder (dimma, duggregn)’ och syftar antagligen på att forsen orsakade dimma om vintern.</p></div>"
      actual = solig.unword(letsi).to_s
      expect(actual).to eq expected
    end

    it "replaces the Unicode spaces" do
      lilla_tjärby = loadparagraph '3426-lilla-tjärby'
      formatted = solig.unword(lilla_tjärby)
      expected = "<div xml:id='Lilla_Tjärby' type='?'><head><placeName>Lilla Tjärby</placeName></head> <p><span type='locale'>tätort</span>, <location><district type='socken'>Laholms sn</district><district type='härad'>Höks hd</district><region type='landskap'>Halland</region></location>. – Tätorten har namn efter en intilliggande by, ursprungligen en del av byn Tjärby i grannsocknen → <span type='kursiv'>Tjärby</span>. Namnet <span type='kursiv'>Lilla Tjärby</span> är belagt från mitten av 1600-talet. </p></div>"
      actual = formatted.to_s
      # byebug
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
      # byebug
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

    it "remaps initial - to _ for id’s" do
      w = XPath.first(Document.new("<w:document xmlns:w=''><w:p><w:r><w:rPr><w:b /></w:rPr><w:t>-unga</w:t></w:r><w:r><w:t> </w:t></w:r><w:r><w:t>namnelement.</w:t></w:r></w:p></w:document>"), "/w:document/w:p")
      expect(solig.unword(w).to_s).to eq "<div xml:id='_unga' type='?'><head><placeName>-unga</placeName></head> <p><span type='locale'>namnelement.</span></p></div>"
    end

    it "works on -unga" # No extraneous comma
    it "works on Unnaryd" # Recognises Småland etc. as geographic features, and does something reasonable with resp.
    it "works on Uppsala län"
    it "works on Vájsáluokta" # No extraneous comma
    it "works on Vantör" # Församling!  And sensible punctuation and spacing around (De)

    it "works on Ume lappmark" do
      ume_lappmark = loadparagraph '5848-ume-lappmark'
      expected = "<div xml:id='Ume_lappmark' type='?'><head><placeName>Ume lappmark</placeName></head> <p><span type='locale'>del av Lappland</span>. – Namnet är ursprungligen en historisk-administrativ benämning på samebygden som handels- och beskattningsområde. Det är givet efter huvudorten → <span type='kursiv'>Umeå</span> i Västerbotten.</p></div>"
      actual = solig.unword(ume_lappmark).to_s
      # byebug
      expect(actual).to eq expected
      pending "Maybe even later"
      expect(actual).to eq "<div xml:id='Ume_lappmark' type='?'><head><placeName>Ume lappmark</placeName></head> <p><span type='locale'>del av</span><location> <region type='landskap'>Lappland</region></location>. – Namnet är ursprungligen en historisk-administrativ benämning på samebygden som handels- och beskattningsområde. Det är givet efter huvudorten → <span type='kursiv'>Umeå</span> i Västerbotten.</p></div>"
      pending "Maybe even even later"
      expect(actual).to eq "<div xml:id ='Ume_lappmark' type='?'><head><placeName>Ume lappmark</placeName></head> <p><span type='locale'>del av <location><region type='landskap'>Lappland</region></location></span>. – Namnet är ursprunligen en historisk-administrativ benämning på samebygden som handels- och beskattningsområde. Det är givet efter huvudorten → <span type='kursiv'>Umeå</span> i Västerbotten.</p></div>"
    end

    it "works on Umeå" do
      umeå = loadparagraph '5849-umeå'
      # pending "later"
      actual = solig.unword(umeå).to_s
      # byebug
      expect(actual).to be =~ /<div xml:id='Umeå' type='\?'><head><placeName>Umeå<\/placeName><\/head> <p><span type='locale'>kn<\/span>, <span type='locale'>stad<\/span>, <span type='locale'>sn<\/span>, <location><region type='landskap'>Västerbotten<\/region><\/location>/
    end

    it "outputs (de) correctly for Umeå" do
      umeå = loadparagraph '5849-umeå'
      actual = solig.unword(umeå).to_s
      # byebug
      expect(actual).to be =~ /(<span type='kursiv'>de<\/span>)/
    end
  end

  describe 'Intensive tests for #unword' do
    it "doesn’t crash on Undersåker" do
      undersåker = loadparagraph '5855-undersåker'
      expect { solig.unword(undersåker) }.not_to raise_error
    end

    it "works on Västra Skrävlinge" do
      västra_skrävlinge = loadparagraph '6317-västra-skrävlinge'
      expected = "<div xml:id='Västra_Skrävlinge' type='?'><head><placeName>Västra Skrävlinge</placeName></head> <p><span type='locale'>f.d. sn</span>, <location><district type='härad'>Oxie hd</district><region type='landskap'>Skåne</region></location>. (<span type='kursiv'>de</span>) <span type='kursiv'>Scræplingi</span> 1300-talets mitt, (<span type='kursiv'>de</span>) <span type='kursiv'>Westraskræplinge</span> 1400-talets förra del (avser kyrkbyn). – Socknen har sitt namn efter kyrkbyn. Det innehåller en inbyggarbeteckning (→ -<span type='kursiv'>inge</span>), kanske bildad till ett äldre namn på Husiebäcken, sammanhängande med verbet <span type='kursiv'>skrapa</span> med syftning på vattnets ljud. Kyrkbyn och grannbyn Östra Skrävlinge i Husie f.d. socken utgjorde äldst en enda bebyggelse.</p></div>"
      actual = solig.unword(västra_skrävlinge).to_s
      # pending "Later"
      # byebug
      expect(actual).to eq expected
    end

    it "works on Lilla och Stora Värtan" do
      stora_och_lilla_värtan = loadparagraph '6231-stora-och-lilla-värtan'
      expected = "<div xml:id='Värtan._Stora._Lilla' type='?'><head><placeName>Värtan, Stora, Lilla</placeName></head> <p><span type='locale'>fjärdar i Saltsjön i Upplandsdelen av Stockholms inre skärgård</span>. <span type='kursiv'>Wärtänn</span>, <span type='kursiv'>Wärtenn</span>, <span type='kursiv'>Wertenn</span> (1558). – Namnet kan sammanhänga med ordet <span type='kursiv'>vårta</span>, dock med oviss syftning.</p></div>" # FIXME Not much idea what to do! "<div xml:id='Värtan._Stora._Lilla'><head>Värtan, Stora, Lilla</head> <p><span type='locale'>fjärdar</span> i Upplandsdelen av <location><settlement type='stad'>Stockholms inre skärgård </p></div>"
      actual = solig.unword(stora_och_lilla_värtan).to_s
      # pending "That’s going to be painful"
      # byebug
      expect(actual).to eq expected
    end

    it "works on Västanå" do
      västanå = loadparagraph '6242-västanå'
      # pending "later"
      expected = "<div xml:id='Västanå' type='?'><head><placeName>Västanå</placeName></head> <p><span type='locale'>gods</span>, <location><district type='landsförsamling'>Gränna lfs</district><district type='härad'>Vista hd</district><region type='landskap'>Småland</region></location>. <span type='kursiv'>Westan</span> <span type='kursiv'>a</span> 1412. Namnet är givet efter läget väster om Röttleån (jfr → <span type='kursiv'>Östanå</span>).</p></div>" # Inte Skåne! # FIXME Kanske i källan?
      actual = solig.unword(västanå).to_s
      # byebug
      expect(actual).to eq expected
    end

    it "works on Västanfors" do
      västanfors = loadparagraph '6240-västanfors'
      expected = "<div xml:id='Västanfors' type='?'><head><placeName>Västanfors</placeName></head> <p><span type='locale'>f.d. sn</span>, <span type='locale'>nu stadsdel</span>, <location><settlement type='stad'>Fagersta stad</settlement><region type='landskap'>Västmanland</region></location>. – Det gamla sockennamnet <span type='kursiv'>Västanfors</span> avsåg ursprungligen en järnframställningshytta (<span type='kursiv'>Westhan forss</span> 1486). Namnet åsyftar hyttans läge väster om en fors i Kolbäcksån. 1944 ombildades socknen, vars tätort kring kyrkan och den gamla bruksbebyggelsen varit municipalsamhälle sedan 1927, till staden → <span type='kursiv'>Fagersta</span>.</p></div>"
      actual = solig.unword(västanfors).to_s
      # byebug
      expect(actual).to eq expected
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
      # byebug
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
      w = XPath.first(Document.new("<w:document xmlns:w=''><w:p><w:r><w:rPr><w:b /></w:rPr><w:t>Ingelstad</w:t></w:r><w:r><w:t> </w:t></w:r><w:r><w:t>tätort, Östra Torsås sn, Konga hd, Småland.</w:t></w:r></w:p></w:document>"), '/w:document/w:p')
      expected = "<div xml:id='Ingelstad' type='?'><head><placeName>Ingelstad</placeName></head> <p><span type='locale'>tätort</span>, <location><district type='socken'>Östra Torsås sn</district><district type='härad'>Konga hd</district><region type='landskap'>Småland</region></location>.</p></div>"
      actual = solig.unword(w).to_s
      # byebug
      expect(actual).to eq expected
    end

    it "escapes id’s properly" do
      w = XPath.first(Document.new("<w:document xmlns:w=''><w:p><w:r><w:rPr><w:b /></w:rPr><w:t>Mellby, Norra, Södra</w:t></w:r><w:r><w:t> </w:t></w:r><w:r><w:t>snr, Kållands hd, Västergötland.</w:t></w:r></w:p></w:document>"), '/w:document/w:p')
      expected = "<div xml:id='Mellby._Norra._Södra' type='?'><head><placeName>Mellby, Norra, Södra</placeName></head> <p><span type='locale'>snr</span>, <location><district type='härad'>Kållands hd</district><region type='landskap'>Västergötland</region></location>.</p></div>"
      actual = solig.unword(w).to_s
      expect(actual).to eq expected
    end

    it "adds an empty bebyggelsenamn" do
      w = XPath.first(Document.new("<w:document xmlns:w=''><w:p><w:r><w:rPr><w:b /></w:rPr><w:t>Kattorp</w:t></w:r><w:r><w:t> </w:t></w:r><w:r><w:t>sn, tätort, Luggude hd, Skåne.</w:t></w:r></w:p></w:document>"), '/w:document/w:p')
      expected = "<div xml:id='Kattorp' type='?'><head><placeName>Kattorp</placeName></head> <p><span type='locale'>sn</span>, <span type='locale'>tätort</span>, <location><district type='härad'>Luggude hd</district><region type='landskap'>Skåne</region></location>.</p></div>"
      actual = solig.unword(w).to_s
      expect(actual).to eq expected
    end

    it "doesn’t raise an error on -arp" do
      arp = loadparagraph '597-arp'
      expect { solig.unword arp }.not_to raise_error
    end

    it "doesn’t raise an error on benning" do # Crash line 167
      benning = loadparagraph '704-benning'
      expect { solig.unword benning }.not_to raise_error
    end

    it "doesn’t raise an error on bo" do # Crash line 153
      bo2 = loadparagraph '874-bo-andra-paragraf'
      expect { solig.unword bo2 }.not_to raise_error
    end

    # FIXME Paragraph probably shouldn’t be on its own
    it "doesn‘t raise an error on bod" do # Crash line 148
      bod3 = loadparagraph '888-bod-tredje-paragraf'
      expect { solig.unword bod3 }.not_to raise_error
    end

    it "sees the hyphen on 888?"

    it "doesn’t crash on the last paragraph of the description for -inge" do # Line 219
      inge_last = loadparagraph '2749-inge-sista-tolknings-paragraf'
      expect { solig.unword(inge_last) }.not_to raise_error
    end

    # FIXME Kiruna *stad*?  It’s more the tag that’s questionable, of course.
    it "works on Abisko" do # förs. as a location type
      abisko = loadparagraph '448-abisko'
      expected = "<div xml:id='Abisko' type='?'><head><placeName>Abisko</placeName></head> <p><span type='locale'>nationalpark</span>, <span type='locale'>turistort</span>, <location><district type='församling'>Jukkasjärvi förs.</district><settlement type='stad'>Kiruna stad</settlement><region type='landskap'>Lappland</region></location>. – Namnet är en försvenskning av nordsam. <span type='kursiv'>Ábeskovvu</span>, vars efterled återgår på svenskans och norskans <span type='kursiv'>skog</span>. Förleden är genitiv singularis av sam. <span type='kursiv'>áhpi</span> ’hav, stort vatten’ (nordiskt lånord). Namnet kan möjligen tolkas som ’skogen vid havet (det stora vattnet, dvs. Torneträsk)’. En annan möjlighet är att namnet syftar på skogens sträckning till norska kusten.</p></div>"
      actual = solig.unword(abisko).to_s
      # byebug
      expect(actual).to eq expected
    end

    it "works on Álggavárre" do # nationalpark as a location type
      álggavárre = loadparagraph '486-álggavárre'
      expected = "<div xml:id='Álggavárre' type='?'><head><placeName>Álggavárre</placeName></head> <p><span type='locale'>fjäll</span>, <location><district type='nationalpark'>Sareks nationalpark</district><district type='socken'>Jokkmokks sn</district><region type='landskap'>Lappland</region></location>. <span type='kursiv'>Alkiewari</span> 1768. – Förleden i det lulesamiska namnet (med försvenskad stavning <span type='kursiv'>Alkavare</span>) innehåller en bildning till verbet <span type='kursiv'>álgget</span> ’börja’, kanske med syftning på att dalgångarna österut har sin början här. Efterleden <span type='kursiv'>várre</span> betyder ’berg, fjäll’. Fjället är känt genom ett samiskt kapell samt gruvverksamhet under slutet av 1600-talet.</p></div>"
      actual = solig.unword(álggavárre).to_s
      # byebug
      expect(actual).to eq expected
    end

    it "works on Bjärsgård" do # kn as a location type
      bjärsgård = loadparagraph '798-bjärsgård'
      expected = "<div xml:id='Bjärsgård' type='?'><head><placeName>Bjärsgård</placeName></head> <p><span type='locale'>gods</span>, <location><district type='kommun'>Klippans kn</district><region type='landskap'>Skåne</region></location>. (<span type='kursiv'>i</span>) <span type='kursiv'>Bierssgardt</span> 1503. – Godset är beläget i f.d. Gråmanstorps socken, Norra Åsbo härad. Huvudbyggnaden ligger på en liten holme i Borgasjön nära sjöns södra strandkant. Namnets förled, genitiv av fda. <span type='kursiv'>biærgh</span> ’berg’, åsyftar ett markant höjdparti vid stranden mitt emot holmen.</p></div>"
      actual = solig.unword(bjärsgård).to_s
      # byebug
      expect(actual).to eq expected
    end

    it "works on Finnveden" # hdr, not consistent with hd in other places (as pl. too)
    it "works on Fjärmåla" # kapellförs.
    it "recognises f.d. on Fudal"
    it "works on Hardemo" # Weird tagging around parenthesese
    it "works on Husie" # “(f.d. sn” comfuses things
    it "works on Hörsne" # Funny repeating bug? “sn (fullständigt namn” appearing twice
    it "works on Jättene" # o. for och!
    it "works on Karlaby" # Beginning of description repeated!
    it "works on Kulladal" # Invalid tag crossing over the full stop.
    it "works on Löderup" # Complicated use of samt
    it "works on Markaryd" # Simple use of samt
    it "works on Möckeln" # köping as location type!
    it "works on Möckelby, Norra, Södra" # Use of resp
    it "works on Norberg" # bergslag as location type
    it "works on Näset" # “officiellt” repeated
    it "works on Oppunda härad" # Second paragraph has “Vid sidan av” repeated
    it "works on Kapparmora" # bound to be confused by “och”!
    it "works on Kolsva" # with “(f.d. sn)” in parentheses.  Are they necessary, though?

    it "doesn’t change paragraphs starting with regular type"
    it "doesn’t change either paragraphs starting with a headword in lowercase"
  end

  describe '#start_location'

  describe '#add_location_element' do
    it "adds a location element" do
      styra = Document.new "<div><head>Styra</head> <p><span type='locale'>sn</span> <location></location></p></div>"
      p = XPath.first(styra, 'div/p/location')
      solig.instance_variable_set(:@currelem, p)

      solig.add_location_element 'Aska hd'

      expect(styra.to_s).to eq "<div><head>Styra</head> <p><span type='locale'>sn</span> <location><district type='härad'>Aska hd</district></location></p></div>"
    end
  end

  describe '#add_head_element' do
    it "adds a head element" do
      article = Document.new "<div xml:id='Abisko' type='bebyggelsenamn'></div>"
      solig.instance_variable_set(:@currelem, article.root)
      solig.add_head_element 'Abisko'
      expect(article.to_s).to eq "<div xml:id='Abisko' type='bebyggelsenamn'><head><placeName>Abisko</placeName></head></div>"
    end

    it "does not strip the input" do
      article = Document.new "<div xml:id='Bockara' type='bebyggelsenamn'></div>"
      solig.instance_variable_set(:@currelem, article.root)
      solig.add_head_element ' Bockara '
      expect(article.to_s).to eq "<div xml:id='_Bockara_' type='bebyggelsenamn'><head><placeName> Bockara </placeName></head></div>"
    end
  end

  describe '.add_escaped_text' do
    it "interprets the escape sequences" do
      doc = Document.new "<doc><p></p></doc>"
      element = doc.root.elements.first
      Solig.add_escaped_text element, "foo \\fd bar"
      expect(element.text).to eq "foo f.d. bar"
    end

    it "doesn’t crash on nil input" do
      root = Document.new("<doc></doc>").root
      expect { Solig.add_escaped_text root, nil }.not_to raise_error
    end
  end

  describe '#add_locale_element' do
    it "adds a locale" do
      styra = Document.new('<div><head>Styra</head> <p></p></div>')
      p = XPath.first(styra, 'div/p')
      solig.instance_variable_set(:@currelem, p)

      solig.add_locale_element 'sn'

      expect(styra.to_s).to eq "<div><head>Styra</head> <p><span type='locale'>sn</span></p></div>"
    end
  end
end
