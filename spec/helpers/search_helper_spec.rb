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

    it "will change to allocate if there is no allocation" do
      offender = Nomis::Offender.new(
        offender_no: 'A',
        tier: 'A'
      )
      text, _link = cta_for_offender('LEI', offender)
      expect(text).to eq('<a href="/prisons/LEI/allocations/A/new">Allocate</a>')
    end

    it "will change to view if there is an allocation" do
      offender = Nomis::Offender.new(
        offender_no: 'A',
        tier: 'A',
        allocated_pom_name: 'Bob'
      )
      text, _link = cta_for_offender('LEI', offender)
      expect(text).to eq('<a href="/prisons/LEI/allocations/A">View</a>')
    end
  end
end
