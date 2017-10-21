require 'spec_helper'

describe Sol do
  let(:sol) { Sol.new }

  # TODO Hard examples Bålsta kn
  describe '#process' do
    it "processes a few entries" do
      out = sol.process('Husby sn, tätort, Dalarna')
      expect(out).to eq '<head><placeName>Husby</placeName></head> <P><locale>sn</locale>, <locale>tätort</locale>, <location><region type="landskap">Dalarna</region></location>'
      out = sol.process('Hurva sn, tätort, Frosta hd, Skåne')
      expect(out).to eq '<head><placeName>Hurva</placeName></head> <P><locale>sn</locale>, <locale>tätort</locale>, <location><district type="härad">Frosta hd</district>, <region type="landskap">Skåne</region></location>'
      out = sol.process('Vätteryd torp, gravfält, Norra Mellby sn, Västra Göinge hd, Skåne')
      expect(out).to eq '<head><placeName>Vätteryd</placeName></head> <P><locale>torp</locale>, <locale>gravfält</locale>, <district type="socken">Norra Mellby sn</district>, <district type="härad">Västra Göinge hd</district>, <region type="landskap">Skåne</region>'
    end
  end
end
