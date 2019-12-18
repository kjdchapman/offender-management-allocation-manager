# frozen_string_literal: true

module Nomis
  class Offender < OffenderBase
    include Deserialisable

    attr_accessor :main_offence

    attr_reader :gender, :prison_id,
                :nationalities,
                :noms_id

    attr_reader :reception_date

    def initialize(fields = {})
      super fields
      # Allow this object to be reconstituted from a hash, we can't use
      # from_json as the one passed in will already be using the snake case
      # names whereas from_json is expecting the elite2 camelcase names.
      @gender = fields[:gender]
      @booking_id = fields[:booking_id]
      @main_offence = fields[:main_offence]
      @nationalities = fields[:nationalities]
      @noms_id = fields[:noms_id]
      @prison_id = fields[:prison_id]
      @reception_date = fields[:reception_date]
    end

    def self.from_json(payload)
      Offender.new.tap { |obj|
        obj.load_from_json(payload)
      }
    end

    def load_from_json(payload)
      @gender = payload['gender']
      @booking_id = payload['latestBookingId']&.to_i
      @main_offence = payload['mainOffence']
      @nationalities = payload['nationalities']
      @noms_id = payload['nomsId']
      @prison_id = payload['latestLocationId']
      @reception_date = deserialise_date(payload, 'receptionDate')

      super(payload)
    end
  end
end
