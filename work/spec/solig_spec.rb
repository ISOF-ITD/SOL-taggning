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

  describe '#isitalic' do
    it "returns true if text bit is italic" do
      doc = REXML::Document.new "<w:document xmlns:w='somelink'><w:r><w:rPr><w:i /></w:rPr></w:r></w:document>"
      text = doc.root.elements.first
      expect(text.isitalic).to be_truthy
    end

    it "returns false otherwise" do
      doc = REXML::Document.new "<w:document xmlns:w='ns'><w:r><w:rPr></w:rPr></w:r></w:document>"
      text = doc.root.elements.first
      expect(text.isitalic).to be_falsey
    end

    it "doesn’t crash if element doesn’t conform to the .docx format" do
      doc = REXML::Document.new "<w:document xmlns:w='ns'><w:p></w:p></w:document>"
      text = doc.root.elements.first
      expect { text.isitalic }.to_not raise_error
    end
  end

  describe '#isbold' do
    it "returns true if text bit is bold" do
      doc = REXML::Document.new "<w:document xmlns:w=''><w:r><w:rPr><w:b /></w:rPr></w:r></w:document>"
      bold = doc.root.elements.first
      expect(bold.isbold).to be_truthy
    end

    it "returns false otherwise" do
      doc = REXML::Document.new "<w:document xmlns:w=''><w:r><w:rPr></w:rPr></w:r></w:document>"
      notbold = doc.root.elements.first
      expect(notbold.isbold).to be_falsey
    end

    it "doesn’t crash if element doesn’t have an rPr child" do
      doc = REXML::Document.new "<w:document xmlns:w=''><w:p></w:p></w:document>"
      not_a_text_bit = doc.root.elements.first
      expect(not_a_text_bit.isbold).to be_falsey
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
end

describe Solig do
  let(:solig) { Solig.new }

  describe '#process' do
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
    it "processes entries with f. d."
    it "processes entries with longer strings such as the one for Kattegatt"

    it "stops at the first full stop" do
      abbekås = loadparagraph '444-abbekås'
      form = solig.unword(abbekås)
      actual = form.to_s
      expected = "<div><head><placeName>Abbekås</placeName></head> <p><span type='locale'>tätort</span>, <location><district type='socken'>Skivarps sn</district><district type='härad'>Vemmenhögs hd</district><region type='landskap'>Skåne</region></location>. <span style='italic'>Abbekassz</span> 1536. – Namnet på detta gamla fiskeläge innehåller troligen mansnamnet fda. <span style='italic'>Abbi</span>. Efterleden är dialektordet <span style='italic'>kås</span> ’båtplats, mindre hamn’.</p></div>"
      expect(actual).to eq expected
    end

    it "calls a city a settlement" do
      abborrberget = loadparagraph '445-abborrberget'
      formatted = solig.unword abborrberget
      pending "This is just bizarre.  Strä[new element]ngnäs"
      expect(formatted.to_s).to be =~ /<div><head><placeName>Abborrberget<\/placeName><\/head> <p><span type='locale'>tätort<\/span>, <location><settlement type='stad'>Strängnäs stad<\/settlement><region type='landskap'>Södermanland<\/region><\/location>/ # FIXME Allow non-landskap areas as last entries!
    end
  end

  describe "#unweave" do
    it "unweaves a table" do
      unweaved = solig.unweave <<__EoTable__
        <Table>
          <TR>
            <TD>This line is supposed to be combined with</TD>
            <TD>while that one has to go with</TD>
          </TR>
          <TR>
            <TD>this line here</TD>
            <TD>that one over there</TD>
          </TR>
        </Table>
__EoTable__

      expect unweaved == 'This line is supposed to be combined with this line here while that one has to go with that one over there'
    end
  end

  describe '#unlist' do
    it "unlists a list" do
      unlisted = solig.unlist <<__EoList__
        <L>
          <LI>
            <Lbl>—</Lbl>

            <LBody>Nordiska bebyggelsenamn ur språklig synvinkel I: NoB 103 (2015). S. 9–23.</LBody>
          </LI>

          <LI>
            <Lbl>—</Lbl>

            <LBody>Om ortnmanssuffixet -str-. I: NoB 63 (1975). S. 143–63.</LBody>
          </LI>
        </L>
__EoList__
      expect unlisted == <<_EoDiv_
        <div>
          <p>Nordiska bebyggelsenamn ur språklig synvinkel I: NoB 103 (2015). S. 9–23.</p>

          <p>Om ortnamnssuffixet -str-. I: NoB 63 (1975). S. 143–63.</p>
        </div>
_EoDiv_
    end

    it "deals with interspersed p’s" do
      unlisted = solig.unlist <<_EoListWithP_
        <root>
          <L>
            <LI>
              <Lbl>—</Lbl>

              <LBody>Die Suffixbildungen in der altgermanischen Toponymie.</LBody>
            </LI>
          </L>

          <p>I: Suffixbildungen in alten Ortsnamen (se detta). S. 13–26.</p>

          <L>
            <LI>
              <Lbl>—</Lbl>

              <LBody>Svenska häradsnamn. Uppsala–Köpenhamn 1965. (Nomina Germanica 14.)</LBody>
            </LI>
          </L>
        </root>
_EoListWithP_

      result = <<_EoJustP_
<root>
  <p>Die Suffixbildungen in der altgermanischen Toponymie.</p>

  <p>I: Suffixbildungen in alten Ortsnamen (se detta). S. 13–26.</p>

  <p>Svenska häradsnamn. Uppsala–Köpenhamn 1965. (Nomina Germanica 14.)</p>
</root>
_EoJustP_
      expect(unlisted).to eq result.strip
    end

    it "passes figure elements as is (almost)" do
      unlisted = solig.unlist <<__END__
        <root>
          <p>Nordische Ortsnamen aus germanischer Perspektive. I:  Onoma 37 (2002). S. 95–120.</p>

          <figure>
            <graphic url="bilder/SOL2_img_1577.jpg" />
          </figure>
        </root>
__END__

      result = <<__END__
<root>
  <p>Nordische Ortsnamen aus germanischer Perspektive. I:  Onoma 37 (2002). S. 95–120.</p>

  <figure><graphic url="bilder/SOL2_img_1577.jpg" /></figure>
</root>
__END__
      expect(unlisted).to eq result.strip
    end

    it "raises an error if it has any other element than L, p, or figure" do
      expect { solig.unlist "<root><foo>bar</foo></root>" }.to raise_error UnexpectedElement
    end
  end

  describe '#load' do
    it "loads a contentious div" do
      div = solig.load
      p = div.elements.first
      expect(p.name).to eq 'p'
      expect(p.text).to eq 'A '
    end
  end

  describe '#unword' do
    it "dismantles the Word XML structure" do
      bro = loadparagraph '1023-bro'
      pending "This is going to be painful"
      expect(solig.unword(bro).to_s).to eq "<div><head><placeName>Bro</placeName></head> <p><span type='locale'>sn</span>, <location><district type='skeppslag'>Bro och Vätö skg</district><region type='landskap'>Uppland</region></location> → <span style='italic'>Roslags-Bro</span>.</p></div>"
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

    it "works on entries 459, 460, 461, 465, 474, 3383"

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
end
