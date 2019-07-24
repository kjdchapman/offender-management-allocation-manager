# frozen_string_literal: true

class AllocationVersion < ApplicationRecord
  has_paper_trail

  ALLOCATE_PRIMARY_POM = 0
  REALLOCATE_PRIMARY_POM = 1
  ALLOCATE_SECONDARY_POM = 2
  REALLOCATE_SECONDARY_POM = 3
  DEALLOCATE_PRIMARY_POM = 4
  DEALLOCATE_SECONDARY_POM = 5

  USER = 0
  OFFENDER_TRANSFERRED = 1
  OFFENDER_RELEASED = 2

  # When adding a new 'event' or 'event trigger'
  # make sure the constant it points to
  # has a value that is sequential and does not
  # re-assign an already existing value
  enum event: {
    allocate_primary_pom: ALLOCATE_PRIMARY_POM,
    reallocate_primary_pom: REALLOCATE_PRIMARY_POM,
    allocate_secondary_pom: ALLOCATE_SECONDARY_POM,
    reallocate_secondary_pom: REALLOCATE_SECONDARY_POM,
    deallocate_primary_pom: DEALLOCATE_PRIMARY_POM,
    deallocate_secondary_pom: DEALLOCATE_SECONDARY_POM
  }

  # 'Event triggers' capture the subject or action that triggered the event
  enum event_trigger: {
    user: USER,
    offender_transferred: OFFENDER_TRANSFERRED,
    offender_released: OFFENDER_RELEASED
  }

  scope :allocations, lambda { |nomis_offender_ids|
    where(nomis_offender_id: nomis_offender_ids)
  }
  scope :all_primary_pom_allocations, lambda { |nomis_staff_id|
    where(
      primary_pom_nomis_id: nomis_staff_id
    )
  }
  scope :active_pom_allocations, lambda { |nomis_staff_id, prison|
    secondaries = where(secondary_pom_nomis_id: nomis_staff_id)

    where(primary_pom_nomis_id: nomis_staff_id).or(secondaries).where(prison: prison)
  }
  scope :active_primary_pom_allocations, lambda { |nomis_staff_id, prison|
    where(
      primary_pom_nomis_id: nomis_staff_id,
      prison: prison
    )
  }

  validate do |alloc|
    if alloc.secondary_pom_nomis_id.present? && alloc.primary_pom_nomis_id.blank? &&
      errors.add("Can't have a secondary POM in an allocation without a primary POM")
    end
  end

  # Note - this only works for active allocations, not ones that have been de-allocated
  # If this returns false it means that we are a secondary/co-working allocation
  def for_primary_only?
    secondary_pom_nomis_id.blank?
  end

  validate do |av|
    if av.primary_pom_nomis_id.present? &&
      av.primary_pom_nomis_id == av.secondary_pom_nomis_id
      errors.add(:primary_pom_nomis_id,
                 'Primary POM cannot be the same as co-working POM')
    end
  end

  def self.last_event(nomis_offender_id)
    allocation = find_by(nomis_offender_id: nomis_offender_id)

    event = event_type(allocation.event)
    event + ' - ' + allocation.updated_at.strftime('%d/%m/%Y')
  end

  def self.event_type(event)
    type = (event.include? 'primary_pom') ? 'POM ' : 'Co-working POM '

    if event.include? 'reallocate'
      type + 're-allocated'
    elsif event.include? 'deallocate'
      type + 'removed'
    elsif event.include? 'allocate'
      type + 'allocated'
    end
  end

  def self.active?(nomis_offender_id)
    allocation = find_by(nomis_offender_id: nomis_offender_id)
    !allocation.nil? && !allocation.primary_pom_nomis_id.nil?
  end

  def override_reasons
    JSON.parse(self[:override_reasons]) if self[:override_reasons].present?
  end

  def self.deallocate_offender(nomis_offender_id, movement_type)
    alloc = AllocationVersion.find_by(
      nomis_offender_id: nomis_offender_id
    )

    return if alloc.nil?

    alloc.primary_pom_nomis_id = nil
    alloc.primary_pom_name = nil
    alloc.primary_pom_allocated_at = nil
    alloc.secondary_pom_nomis_id = nil
    alloc.secondary_pom_name = nil
    alloc.recommended_pom_type = nil
    alloc.event = DEALLOCATE_PRIMARY_POM
    alloc.event_trigger = movement_type
    alloc.prison = nil if alloc.event_trigger == 'offender_released'

    alloc.save!
  end

  def self.deallocate_primary_pom(nomis_staff_id)
    all_primary_pom_allocations(nomis_staff_id).each do |alloc|
      alloc.primary_pom_nomis_id = nil
      alloc.primary_pom_name = nil
      alloc.recommended_pom_type = nil
      alloc.primary_pom_allocated_at = nil
      alloc.event = DEALLOCATE_PRIMARY_POM
      alloc.event_trigger = USER

      alloc.save!
    end
  end

  validates :nomis_offender_id,
            :nomis_booking_id,
            :allocated_at_tier,
            :event,
            :event_trigger, presence: true

  validates :prison, presence: true,
                     unless: proc { |a| a.event_trigger == 'offender_released' }
end
