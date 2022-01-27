require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  context 'authenticated user viewing his page' do
  before do
    user = assign(:user, FactoryBot.build_stubbed(:user, name: 'Вадик'))
    allow(view).to receive(:current_user).and_return(user)
    render
  end

    it 'renders player name' do
      expect(rendered).to match 'Вадик'
    end

    it 'shows option to change player name' do
      expect(rendered).to match 'Сменить имя и пароль'
    end

    it 'renders game partial' do
      assign(:games, [FactoryBot.build_stubbed(:game, id: 15, created_at: Time.parse('2016.10.09, 13:00'), current_level: 10, prize: 1000)])
      stub_template 'users/_game.html.erb' => 'User game goes here'
      render

      expect(rendered).to match 'User game goes here'
    end
  end

  context 'authenticated user viewing others page' do
    before do
      assign(:user, FactoryBot.build_stubbed(:user, name: 'Миша'))
      end

    it 'doesnt show option to change players name' do
      expect(rendered).not_to match 'Сменить имя и пароль'
    end
  end
end