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

    it "processes a simple parish", focus: true do
      out = sol.process('Västrum sn, Södra Tjusts hd, Småland')
      expect(out).to eq '<head><placeName>Västrum</placeName></head> <P><locale>sn</locale>, <location><district type="härad">Södra Tjusts hd</district>, <region type="landskap">Småland</region></location>'
      # FIXME Add forms with ‘och’, see e. g. pp. 176-177.  No plural abbrevation for härad?
    end

    it "handles the case of two härad" do
      out = sol.process('Kinnekulle berg, Kinne och Kinnefjärdings hd, Västergötland')
      expect(out).to eq '<head><placeName>Kinnekulle</placeName></head> <P><locale>berg</locale>, <location><district type="socken">Kinne</district> och </district type="socken">Kinnefjärdings</district> snr, <region type="landsksap">Västergötland</region></location>'
    end

    it "handles the case of two socknar" do
      out = sol.process('Kivik tätort, Södra Mellby och Vitaby snr, Albo hd, Skåne')
      expect(out).to eq '<head><placeName>Kivik</placeName></head> <P><locale>tätort</locale>, <location><district type="socken">Södra Mellby</district> och <district type="socken">Vitaby</district> snr, <district type="härad">Albo hd</district>, <region type="landskap">Skåne</region></location>'
    end

    it "for real!" do
      out = sol.process('Klagshamn samhälle, Västra Klagstorps och Tygelsjö snr, Oxie hd, Skåne')
      expect(out).to eq '<head><placeName>Klagshamn</placeName></head> <P><locale>samhälle</locale>, <location><district type="socken">Västra Klagstorps</district> och <district type="socken">Tygelsjö</district> snr, <district type="härad">Oxie hd</district>, <region type="landskap">Skåne</region></location>'
    end
  end

  # TODO Handle place name elements, f.d., longer strings such as kavsområde
  # avgränsat av Jylland och Själland samt svenska västkusten (Kattegatt)
end
