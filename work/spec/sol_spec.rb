require 'spec_helper'

describe Sol do
  let(:sol) { Sol.new }

  # TODO Hard examples Bålsta kn
  describe '#process' do
    it "processes a parish without a härad" do
      out = sol.process('Husby sn, tätort, Dalarna')
      expect(out).to eq '<head><placeName>Husby</placeName></head> <P><locale>sn</locale>, <locale>tätort</locale>, <location><region type="landskap">Dalarna</region></location>'
    end

    it "processes a parish with an extra locale" do
      out = sol.process('Hurva sn, tätort, Frosta hd, Skåne')
      expect(out).to eq '<head><placeName>Hurva</placeName></head> <P><locale>sn</locale>, <locale>tätort</locale>, <location><district type="härad">Frosta hd</district>, <region type="landskap">Skåne</region></location>'
    end

    it "processes a point with an extra locale" do
      out = sol.process('Vätteryd torp, gravfält, Norra Mellby sn, Västra Göinge hd, Skåne')
      expect(out).to eq '<head><placeName>Vätteryd</placeName></head> <P><locale>torp</locale>, <locale>gravfält</locale>, <location><district type="socken">Norra Mellby sn</district>, <district type="härad">Västra Göinge hd</district>, <region type="landskap">Skåne</region></location>'
    end

    it "processes a parish with a compound name" do
      out = sol.process('Västra Vram sn, Gärds hd, Skåne')
      expect(out).to eq '<head><placeName>Västra Vram</placeName></head> <P><locale>sn</locale>, <location><district type="härad">Gärds hd</district>, <region type="landskap">Skåne</region></location>'
    end

    it "processes a simple parish" do
      out = sol.process('Västrum sn, Södra Tjusts hd, Småland')
      expect(out).to eq '<head><placeName>Västrum</placeName></head> <P><locale>sn</locale>, <location><district type="härad">Södra Tjusts hd</district>, <region type="landskap">Småland</region></location>'
      # FIXME Add forms with ‘och’, see e. g. pp. 176-177.  No plural abbrevation for härad?
    end

    it "handles the case of two härad", focus: true do
      out = sol.process('Kinnekulle berg, Kinne och Kinnefjärdings hd, Västergötland')
      expect(out).to eq '<head><placeName>Kinnekulle</placeName></head> <P><locale>berg</locale>, <location><district type="härad">Kinne</district> och <district type="härad">Kinnefjärdings</district> hd, <region type="landskap">Västergötland</region></location>'
    end

    it "handles the case of two socknar" do
      out = sol.process('Kivik tätort, Södra Mellby och Vitaby snr, Albo hd, Skåne')
      expect(out).to eq '<head><placeName>Kivik</placeName></head> <P><locale>tätort</locale>, <location><district type="socken">Södra Mellby</district> och <district type="socken">Vitaby</district> snr, <district type="härad">Albo hd</district>, <region type="landskap">Skåne</region></location>'
    end

    it "for real!" do
      out = sol.process('Klagshamn samhälle, Västra Klagstorps och Tygelsjö snr, Oxie hd, Skåne')
      expect(out).to eq '<head><placeName>Klagshamn</placeName></head> <P><locale>samhälle</locale>, <location><district type="socken">Västra Klagstorps</district> och <district type="socken">Tygelsjö</district> snr, <district type="härad">Oxie hd</district>, <region type="landskap">Skåne</region></location>'
    end

    it "processes the entry for Norberg"
  end

  # TODO Handle place name elements, f.d., longer strings such as kavsområde
  # avgränsat av Jylland och Själland samt svenska västkusten (Kattegatt)

  describe "#unweave" do
    it "unweaves a table" do
      unweaved = sol.unweave <<__EoTable__
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
      unlisted = sol.unlist <<__EoList__
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
      unlisted = sol.unlist <<_EoListWithP_
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
  end
end
