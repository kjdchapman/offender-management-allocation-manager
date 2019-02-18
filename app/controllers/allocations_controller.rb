class AllocationsController < ApplicationController
  before_action :authenticate_user

  def show
    @prisoner = OffenderService.new.get_offender(nomis_offender_id_from_url)
    @recommended_pom = @prisoner.current_responsibility

    pom_response = PrisonOffenderManagerService.get_poms(caseload) { |pom|
      pom.status == 'active'
    }
    @recommended_poms, @not_recommended_poms = pom_response.partition { |pom|
      pom.position_description.include?(@recommended_pom)
    }
  end

  def new
    @prisoner = OffenderService.new.get_offender(nomis_offender_id_from_url)
    @pom = PrisonOffenderManagerService.get_pom(caseload, nomis_staff_id_from_url)
  end

  # rubocop:disable Metrics/MethodLength
  def create
    prisoner  = OffenderService.new.
      get_offender(allocation_params[:nomis_offender_id])
    @override = Override.where(
      nomis_offender_id: allocation_params[:nomis_offender_id]).
      where(nomis_staff_id: allocation_params[:nomis_staff_id]).last

    AllocationService.create_allocation(
      nomis_staff_id: allocation_params[:nomis_staff_id].to_i,
      nomis_offender_id: allocation_params[:nomis_offender_id],
      created_by: current_user,
      nomis_booking_id: prisoner.latest_booking_id,
      allocated_at_tier: prisoner.tier,
      prison: caseload,
      override_reasons: override_reasons,
      override_detail: override_detail
    )

    redirect_to summary_path(anchor: 'awaiting-allocation')
  end
  # rubocop:enable Metrics/MethodLength

private

  def nomis_offender_id_from_url
    params.require(:nomis_offender_id)
  end

  def nomis_staff_id_from_url
    params.require(:nomis_staff_id)
  end

  def allocation_params
    params.require(:allocate).permit(:nomis_staff_id, :nomis_offender_id)
  end

  def override_reasons
    @override[:override_reasons] if @override.present?
  end

  def override_detail
    @override[:more_detail] if @override.present?
  end
end
