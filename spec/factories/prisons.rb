FactoryBot.define do
  class Elite2Prison
    attr_accessor :code
  end

  factory :prison, class: 'Elite2Prison' do
    # rotate around every prison - can't use arbitrary codes as we sometimes lookup names in PrisonService
    sequence(:code) do |c|
      codes = PrisonService.prison_codes
      codes[c % codes.size]
    end
  end
end
