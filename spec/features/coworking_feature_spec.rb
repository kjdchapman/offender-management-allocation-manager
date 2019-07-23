require 'rails_helper'

feature 'Co-working' do
  let!(:nomis_offender_id) { 'G4273GI' }
  let!(:probation_pom) do
    {
      staff_id: 485_752,
      pom_name: 'Ross Jones',
      email: 'Ross.jonessss@digital.justice.gov.uk'
    }
  end

  let!(:secondary_pom) do
    {
      staff_id: 485_637,
      pom_name: 'Kath Pobee-Norris',
      email: 'kath.pobee-norris@digital.justice.gov.uk'
    }
  end

  let!(:allocation) {
    create(
      :allocation_version,
      nomis_offender_id: nomis_offender_id,
      primary_pom_nomis_id: probation_pom[:staff_id],
      primary_pom_name: probation_pom[:pom_name],
      recommended_pom_type: 'probation'
    )
  }

  let(:secondary_alloc) { allocation.reload }

  before(:each) do
    signin_user
  end

  scenario 'show allocate a co-working POM page', vcr: { cassette_name: :show_allocate_coworking_page } do
    visit new_prison_coworking_path('LEI', nomis_offender_id)

    expect(page).to have_link 'Back', href: prison_allocation_path('LEI', nomis_offender_id: nomis_offender_id)
    expect(page).to have_link('Allocate')
    expect(page).to have_css('h1', text: 'Allocate a co-working Prison Offender Manager')
    expect(page).to have_css('.govuk-table', count: 4)

    co_working_content = [
        'Prisoner Name Abbella, Ozullirn',
        'Date of birth 15/08/1980',
        'Prisoner number G4273GI',
        'Current POM Name',
        'Grade',
        'Available POMs',
        'Probation Officer POMs',
        'Prison Officer POMs'
    ]

    co_working_content.each do |text|
      expect(page).to have_content(text)
    end

    expect(page).not_to have_content('unavailable POM')

    inactive_poms = [485_734, 485_833]
    inactive_texts = ['There is 1 unavailable POM for new allocation',
                      'There are 2 unavailable POMs for new allocation']

    inactive_poms.each_with_index do |pom, i|
      visit edit_prison_pom_path('LEI', pom)
      choose('working_pattern-ft')
      choose('Inactive')
      click_button('Save')

      visit new_prison_coworking_path('LEI', nomis_offender_id)
      expect(page).to have_content(inactive_texts[i])
    end
  end

  scenario 'show confirm co-working POM allocation page', vcr: { cassette_name: :show_confirm_coworking_page } do
    visit prison_confirm_coworking_allocation_path(
      'LEI',
      nomis_offender_id, probation_pom[:staff_id], secondary_pom[:staff_id]
          )

    expect(page).to have_content("Confirm co-working allocation")
    expect(page).to have_content("You are allocating #{secondary_pom[:pom_name]} to work with #{probation_pom[:pom_name]} on Ozullirn Abbella")
    expect(page).to have_content("We will send a confirmation email to #{secondary_pom[:email]}")
    expect(page).to have_button('Complete allocation')
    expect(page).to have_link('Cancel')

    fill_in 'message', with: 'Some new information'

    click_button 'Complete allocation'

    expect(page).to have_current_path('/prisons/LEI/summary/unallocated')

    expect(secondary_alloc.secondary_pom_nomis_id).to eq(secondary_pom[:staff_id])
    expect(secondary_alloc.secondary_pom_name).to eq(secondary_pom[:pom_name].upcase)

    visit prison_allocation_path('LEI', nomis_offender_id)
    within '#co-working-pom' do
      click_link 'Deallocate'
    end

    expect(page).to have_link 'Allocate'
    within '#co-working-pom' do
      expect(page).to have_content('N/A')
    end
  end
end