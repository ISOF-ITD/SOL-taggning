require 'spec_helper'

describe Solig do
  let(:solig) { Solig.new }

  describe '#process' do
    it "returns an XML element" do
      out = solig.process('Vemmenhög')
      expect(out).to be_an REXML::Element
    end

    it "processes a parish without a härad" do
      out = solig.process('Husby sn, tätort, Dalarna')
      expect(out.to_s).to eq "<div><head><placeName>Husby</placeName></head> <p><span type='locale'>sn</span>, <span type='locale'>tätort</span>, <location><region type='landskap'>Dalarna</region></location></p></div>"
    end

    it "processes a parish with an extra locale" do
      out = solig.process('Hurva sn, tätort, Frosta hd, Skåne')
      expect(out.to_s).to eq "<div><head><placeName>Hurva</placeName></head> <p><span type='locale'>sn</span>, <span type='locale'>tätort</span>, <location><district type='härad'>Frosta hd</district><region type='landskap'>Skåne</region></location></p></div>"
    end

    it "processes a point with an extra locale" do
      out = solig.process('Vätteryd torp, gravfält, Norra Mellby sn, Västra Göinge hd, Skåne')
      expect(out.to_s).to eq "<div><head><placeName>Vätteryd</placeName></head> <p><span type='locale'>torp</span>, <span type='locale'>gravfält</span>, <location><district type='socken'>Norra Mellby sn</district><district type='härad'>Västra Göinge hd</district><region type='landskap'>Skåne</region></location></p></div>"
    end

    it "processes a parish with a compound name" do
      out = solig.process('Västra Vram sn, Gärds hd, Skåne')
      expect(out.to_s).to eq "<div><head><placeName>Västra Vram</placeName></head> <p><span type='locale'>sn</span>, <location><district type='härad'>Gärds hd</district><region type='landskap'>Skåne</region></location></p></div>"
    end

    it "processes a simple parish" do
      out = solig.process('Västrum sn, Södra Tjusts hd, Småland')
      expect(out.to_s).to eq "<div><head><placeName>Västrum</placeName></head> <p><span type='locale'>sn</span>, <location><district type='härad'>Södra Tjusts hd</district><region type='landskap'>Småland</region></location></p></div>"
    end

    it "handles the case of two härad", focus: true do
      out = solig.process('Kinnekulle berg, Kinne och Kinnefjärdings hd, Västergötland')
      expect(out.to_s).to eq "<div><head><placeName>Kinnekulle</placeName></head> <p><span type='locale'>berg</span>, <location><district type='härad'>Kinne</district><district type='härad'>Kinnefjärdings</district><region type='landskap'>Västergötland</region></location></p></div>"
    end

    it "handles the case of two socknar" do
      out = solig.process('Kivik tätort, Södra Mellby och Vitaby snr, Albo hd, Skåne')
      expect(out.to_s).to eq "<div><head><placeName>Kivik</placeName></head> <p><span type='locale'>tätort</span>, <location><district type='socken'>Södra Mellby</district><district type='socken'>Vitaby</district><district type='härad'>Albo hd</district><region type='landskap'>Skåne</region></location></p></div>"
    end

    it "for real!" do
      out = solig.process('Klagshamn samhälle, Västra Klagstorps och Tygelsjö snr, Oxie hd, Skåne')
      expect(out.to_s).to eq "<div><head><placeName>Klagshamn</placeName></head> <p><span type='locale'>samhälle</span>, <location><district type='socken'>Västra Klagstorps</district><district type='socken'>Tygelsjö</district><district type='härad'>Oxie hd</district><region type='landskap'>Skåne</region></location></p></div>"
    end

    it "processes the entry for Norberg"
    it "processes the entry for Bålsta (kn och hd osv.)"
    it "processes entries with f. d."
    it "processes entries with longer strings such as the one for Kattegatt"

    it "stops at the first full stop" do
      out = solig.process('Abbekås tätort, Skivarps sn, Vemmenhög hd, Skåne. Abbekassz 1536. – Namnet på detta gamla fiskeläge innehåller troligen mansnamnet fda. Abbi.')
 expect(out.to_s).to eq "<div><head><placeName>Abbekås</placeName></head> <p><span type='locale'>tätort</span>, <location><district type='socken'>Skivarps sn</district><district type='härad'>Vemmenhög hd</district><region type='landskap'>Skåne</region></location>. Abbekassz 1536. – Namnet på detta gamla fiskeläge innehåller troligen mansnamnet fda. Abbi.</p></div>"
    end

    it "calls a city a settlement" do
      out = solig.process('Abborrberget tätort, Strängnäs stad, Södermanland')
      expect(out.to_s).to eq "<div><head><placeName>Abborrberget</placeName></head> <p><span type='locale'>tätort</span>, <location><settlement type='stad'>Strängnäs stad</settlement><region type='landskap'>Södermanland</region></location></p></div>" # FIXME Allow non-landskap areas as last entries!
    end

    it "raises an exception on a unknown location element" do
      expect { solig.process('Golv rum, Trätorp stuga, Vaksala sn') }.to raise_error UnexpectedLocation
    end

    it "has an exclusive list of landskap"
    it "doesn’t screw up on arrows" do
      out = solig.process('Ajmunds gårdnamn, Gotland → Smiss.')
      pending "Maybe forever"
      expect(out.to_s).to eq "<div><head><placeName>Ajmunds</placeName></head> <p><span type='locale'>gårdnamn</span>, <location><region type='landskap'>Gotland</region></location> → Smiss.</p></div>"
    end
  end

  describe '#batch' do
    let(:null) { double("null output").as_null_object }

    it "processes all p children of an element" do
      doc = REXML::Document.new <<__EODOC__
        <root>
          <p>Vákkudavárre fjäll, Gällivare sn, Lappland</p>

          <figure><graphic url="bilder/image_1234.jpg" /></figure>

          <p>Vaksala sn, Vaksala hd, Uppland</p>
        </root>
__EODOC__

      out = solig.batch(doc, null)
      expect(out).to be_a REXML::Document
      xml = <<__EOSTRING__
<root><div><head><placeName>Vákkudavárre</placeName></head> <p><span type='locale'>fjäll</span>, <location><district type='socken'>Gällivare sn</district><region type='landskap'>Lappland</region></location></p></div><figure><graphic url='bilder/image_1234.jpg'/></figure><div><head><placeName>Vaksala</placeName></head> <p><span type='locale'>sn</span>, <location><district type='härad'>Vaksala hd</district><region type='landskap'>Uppland</region></location></p></div></root>
__EOSTRING__
      expect(out.to_s).to eq xml.strip
    end

    it "takes an optional stream argument" do
      stream = double("output stream").as_null_object
      expect(stream).to receive(:puts).with('Processed 1 <p> element')
      doc = REXML::Document.new '<root><p>Hornö behandlingshem, Vallby sn, Trögds hd, Uppland</p></root>'
      out = solig.batch(doc, stream)
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
      p = REXML::Document.new <<__EOP__
      <w:document xmlns:w='http://schemas.openxmlformats.org/wordprocessingml/2006/main'>
        <w:p>
          <w:r>
            <w:rPr>
              <w:b />
            </w:rPr>
            <w:t>Bro</w:t>
          </w:r>
          <w:r>
            <w:t> </w:t>
          </w:r>
          <w:r>
            <w:t>sn, Bro och Vätö skg, Uppland </w:t>
          </w:r>
          <w:r>
            <w:t>→</w:t>
          </w:r>
          <w:r>
            <w:t xml:space='preserve'> </w:t>
          </w:r>
          <w:r>
            <w:rPr>
              <w:i />
            </w:rPr>
            <w:t>Roslags-Bro</w:t>
          </w:r>
          <w:r>
            <w:t>.</w:t>
          </w:r>
        </w:p>
      </w:document>
__EOP__

      expect(solig.unword(p.root.elements.first).to_s).to eq '<div><head>Bro</head> <p>sn, Bro och Vätö skg, Uppland</p></div>'
      # expect(solig.unword(p.root.elements.first).to_s).to eq "<div><p><span type='locale'>sn</span>, <location><district type='skeppslag'>Bro och Vätö skg<district><region type='landskap'>Uppland</region></location>.</div>"
    end
  end
end
