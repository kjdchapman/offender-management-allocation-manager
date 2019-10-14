# frozen_string_literal: true

class RecommendationService
  PRISON_POM = 'PRO'
  PROBATION_POM = 'PO'

  def self.recommended_pom_type(offender)
    if offender.immigration_case?
      PRISON_POM
    elsif ResponsibilityService.calculate_pom_responsibility(offender).custody?
      if %w[A B].include?(offender.tier)
        PROBATION_POM
      else
        PRISON_POM
      end
    else
      PRISON_POM
    end
  end
end
