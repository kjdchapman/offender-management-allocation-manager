require 'rails_helper'

feature 'View a prisoner profile page' do
  it 'shows the prisoner information', :raven_intercept_exception, vcr: { cassette_name: :show_offender_spec } do
    signin_user

    visit prisoner_show_path('G7998GJ')

    expect(page).to have_css('h2', text: 'Ahmonis, Okadonah')
  end

  it 'shows the prisoner image', :raven_intercept_exception, vcr: { cassette_name: :show_offender_spec_image } do
    signin_user

    visit prisoner_image_path('G7998GJ')
    expect(page.response_headers['Content-Type']).to eq('image/jpg')
  end
end
