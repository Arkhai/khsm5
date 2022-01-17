# (c) goodprogrammer.ru

require 'rails_helper'

# Тестовый сценарий для модели Вопрос
#
# Вопрос не содержит функционала (это просто хранилище данных), поэтому все
# тесты сводятся только к проверке наличия нужных валидаций.
#
# Обратите внимание, что работу самих валидаций не надо тестировать (это работа
# авторов rails). Смысл именно в проверке _наличия_ у модели конкретных
# валидаций.
RSpec.describe Question, type: :model do
  context 'validations check' do
    it { should validate_presence_of :level }
    it { should validate_presence_of :text }
    it { should validate_inclusion_of(:level).in_range(0..14) }

    it { should_not allow_value(15).for(:level) }
    it { should allow_value(14).for(:level) }
  end
end
