require 'rails_helper'

RSpec.feature 'USER view others profile', type: :feature do
  let(:user) { create(:user, name: 'Вадик', balance: 5000) }
  let(:other_user) { create(:user, name: 'Миша', balance: 3000) }

  let!(:games) do
    [create(:game, user: other_user, created_at: Time.parse('2021.10.10, 18:00'), current_level: 10, prize: 1000),
     create(:game, user: other_user, created_at: Time.parse('2021.10.09, 13:00'), finished_at: Time.parse('2016.10.09, 13:30'), current_level: 1, prize: 100)]
  end

  before do
    login_as user
  end

  scenario 'user view other user profile' do
    visit '/'
    click_link 'Миша'
    # save_and_open_page

    # 'contains name of the first user'
    expect(page).to have_content 'Вадик'

    # 'contains balance of the first user'
    expect(page).to have_content '5 000 ₽'

    # 'contains name of the other user'
    expect(page).to have_content 'Миша'

    # 'doesnt contains other user balance'
    expect(page).not_to have_content '3 000 ₽'

    # 'contains correct games statuses'
    expect(page).to have_content 'процессе'
    expect(page).to have_content 'деньги'

    # 'contains correct games dates'
    expect(page).to have_content '10 окт., 18:00'
    expect(page).to have_content '09 окт., 13:00'

    # 'contains correct games prizes'
    expect(page).to have_content '1 000 ₽'
    expect(page).to have_content '100 ₽'

    # 'doesnt contain option to change the name'
    expect(page).not_to have_content 'Сменить имя и пароль'
  end
end
