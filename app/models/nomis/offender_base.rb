module Nomis
  class OffenderBase
    delegate :home_detention_curfew_eligibility_date,
             :conditional_release_date, :release_date,
             :parole_eligibility_date, :tariff_date,
             :automatic_release_date,
             to: :sentence

    attr_reader :booking_id, :last_name, :first_name, :offender_no

    attr_accessor :crn, :category_code, :convicted_status,
                  :allocated_pom_name, :case_allocation,
                  :welsh_offender, :tier, :parole_review_date,
                  :sentence, :mappa_level,
                  :ldu, :team, :date_of_birth

    def initialize(fields)
      @first_name = fields[:first_name]
      @last_name = fields[:last_name]
      @offender_no = fields[:offender_no]
      @convicted_status = fields[:convicted_status]
      @sentence_type = SentenceType.new(fields[:inprisonment_status])
      @category_code = fields[:category_code]
      @date_of_birth = fields[:date_of_birth]
      @early_allocation = false
    end

    def load_from_json(payload)
      # It is expected that this method will be called by the subclass which
      # will have been given a payload at the class level, and will call this
      # method from it's own internal from_json
      @first_name = payload['firstName']
      @last_name = payload['lastName']
      @offender_no = payload['offenderNo']
      @convicted_status = payload['convictedStatus']
      @sentence_type = SentenceType.new(payload['imprisonmentStatus'])
      @category_code = payload['categoryCode']
      @date_of_birth = deserialise_date(payload, 'dateOfBirth')
      @early_allocation = false
    end

    def convicted?
      convicted_status == 'Convicted'
    end

    def sentenced?
      # A prisoner will have had a sentence calculation and for our purposes
      # this means that they will either have a:
      # 1) Release date, or
      # 2) Parole eligibility date, or
      # 3) HDC release date (homeDetentionCurfewEligibilityDate field).
      # If they do not have any of these we should be checking for a tariff date
      # Once we have all the dates we then need to display whichever is the
      # earliest one.
      return false if sentence&.sentence_start_date.blank?

      sentence.release_date.present? ||
      sentence.parole_eligibility_date.present? ||
      sentence.home_detention_curfew_eligibility_date.present? ||
      sentence.tariff_date.present? ||
        @sentence_type.indeterminate_sentence?
    end

    def early_allocation?
      @early_allocation
    end

    def nps_case?
      case_allocation == 'NPS'
    end

    def sentence_type_code
      @sentence_type.code
    end

    # sentence type may be nil if we are created as a stub
    def recalled?
      @sentence_type.try(:recall_sentence?)
    end

    def indeterminate_sentence?
      @sentence_type.try(:indeterminate_sentence?)
    end

    def criminal_sentence?
      @sentence_type.civil? == false
    end

    def civil_sentence?
      @sentence_type.civil?
    end

    def describe_sentence
      @sentence_type.description
    end

    def over_18?
      age >= 18
    end

    def immigration_case?
      sentence_type_code == 'DET'
    end

    def earliest_release_date
      sentence.earliest_release_date
    end

    def pom_responsibility
      ResponsibilityService.calculate_pom_responsibility(self)
    end

    def sentence_start_date
      sentence.sentence_start_date
    end

    def full_name
      "#{last_name}, #{first_name}".titleize
    end

    def full_name_ordered
      "#{first_name} #{last_name}".titleize
    end

    # rubocop:disable Rails/Date
    def age
      @age ||= ((Time.zone.now - date_of_birth.to_time) / 1.year.seconds).floor
    end
    # rubocop:enable Rails/Date

    def inprisonment_status=(status)
      @sentence_type = SentenceType.new(status)
    end

    def handover_start_date
      handover.start_date
    end

    def handover_reason
      handover.reason
    end

    def responsibility_handover_date
      handover.handover_date
    end

    def load_case_information(record)
      return if record.blank?

      @tier = record.tier
      @case_allocation = record.case_allocation
      @welsh_offender = record.welsh_offender == 'Yes'
      @crn = record.crn
      @mappa_level = record.mappa_level
      @ldu = record.local_divisional_unit
      @team = record.team.try(:name)
      @parole_review_date = record.parole_review_date
      @early_allocation = record.latest_early_allocation.present? &&
        (record.latest_early_allocation.eligible? || record.latest_early_allocation.community_decision?)
    end

  private

    def handover
      @handover ||= HandoverDateService.handover(self)
    end
  end
end
