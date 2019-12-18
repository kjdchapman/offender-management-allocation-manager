# frozen_string_literal: true

module Nomis
  class OffenderSummary < OffenderBase
    include Deserialisable

    attr_accessor :aliases

    # custom attributes
    attr_accessor :allocation_date, :prison_arrival_date

    attr_reader :prison_id

    def initialize(fields = {})
      super

      @booking_id = fields[:booking_id]
      @prison_id = fields[:prison_id]
    end

    def awaiting_allocation_for
      (Time.zone.today - prison_arrival_date).to_i
    end

    def self.from_json(payload)
      OffenderSummary.new.tap { |obj|
        obj.load_from_json(payload)
      }
    end

    # This list must only contain values that are returned by
    # https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/swagger-ui.html#//locations/getOffendersAtLocationDescription
    def load_from_json(payload)
      @booking_id = payload['bookingId']&.to_i
      @prison_id = payload['agencyId']
      @category_code = payload['categoryCode']

      super(payload)
    end
  end
end
