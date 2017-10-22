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

    it "processes a place with an extra locale" do
      out = sol.process('Vätteryd torp, gravfält, Norra Mellby sn, Västra Göinge hd, Skåne')
      expect(out).to eq '<head><placeName>Vätteryd</placeName></head> <P><locale>torp</locale>, <locale>gravfält</locale>, <district type="socken">Norra Mellby sn</district>, <district type="härad">Västra Göinge hd</district>, <region type="landskap">Skåne</region>'
    end

    it "processes a parish with a compound name" do
      out = sol.process('Västra Vram sn, Gärds hd, Skåne')
      expect(out).to eq '<head><placeName>Västra Vram</placeName></head> <P><locale>sn</locale>, <location><district type="härad">Gärds härad</district>, <region type="landskap">Skåne</region>'
    end

    it "processes a simple parish" do
      out = sol.process('Västrum sn, Södra Tjusts hd, Småland')
      expect(out).to eq '<head><placeName>Västrum</placeName></head> <P><locale>sn</locale>, <location><district type="härad">Södra Tjusts hd</district>, <region type="landskap">Småland</region>'
      # FIXME Add forms with ‘och’, see e. g. pp. 176-177.  No plural abbrevation for härad?
    end
  end
end
