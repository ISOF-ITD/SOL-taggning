require 'spec_helper'

describe Sol do
  let(:sol) { Sol.new }

  # TODO Hard examples Bålsta kn
  describe '#process' do
    it "processes a few entries" do
      out = sol.process('Husby sn, tätort, Dalarna')
      expect(out).to eq '<head><placeName>Husby</placeName></head> <P><locale>sn</locale>, <locale>tätort</locale>, <region type="landskap">Dalarna</region>'
      out = sol.process('Hurva sn, tätort, Frosta hd, Skåne')
      expect(out).to eq '<head><placeName>Hurva</placeName></head> <P><locale>sn</locale>, <locale>tätort</locale>, <region type="härad">Frosta hd</region>, <region type="landskap">Skåne</landskap>'
    end
  end
end
