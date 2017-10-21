require 'spec_helper'

describe Sol do
  let(:sol) { Sol.new }

  describe '#process' do
    it "processes a few entries" do
      out = sol.process('Husby sn, tätort, Dalarna')
    end
  end
end
