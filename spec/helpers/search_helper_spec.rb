require 'rails_helper'

RSpec.describe SearchHelper do
  describe 'the CTA' do
    it "will change to edit if there is no tier" do
      offender = Nomis::Offender.new(
        offender_no: 'A'
      )
      text, _link = cta_for_offender('LEI', offender)
      expect(text).to eq('<a href="/prisons/LEI/case_information/new/A">Edit</a>')
    end

    context 'when there is no allocation' do
      let(:case_info) { build(:case_information, tier: 'A') }

      it "will change to allocate if there is no allocation" do
        offender = Nomis::Offender.new(
          offender_no: 'G1234FX'
          )
        offender.load_case_information(case_info)
        text, _link = cta_for_offender('LEI', offender)
        expect(text).to eq('<a href="/prisons/LEI/allocations/G1234FX/new">Allocate</a>')
      end
    end

    context 'with an allocation' do
      let(:case_info) { build(:case_information, tier: 'A') }

      it "will change to view if there is an allocation" do
        offender = Nomis::Offender.new(
          offender_no: 'G1234FX',
        )
        offender.allocated_pom_name = 'Bob'
        offender.load_case_information(case_info)

        text, _link = cta_for_offender('LEI', offender)
        expect(text).to eq('<a href="/prisons/LEI/allocations/G1234FX">View</a>')
      end
    end
  end
end
