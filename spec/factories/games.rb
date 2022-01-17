# (c) goodprogrammer.ru
#
# Объявление фабрики для создания нужных в тестах объектов
#
# см. другие примеры на
#
# http://www.rubydoc.info/gems/factory_girl/file/GETTING_STARTED.md
FactoryBot.define do
  factory :game do
    # Связь с юзером
    association :user

    # Игра только начата, создаем объект с нужными полями
    finished_at { nil }
    current_level { 0 }
    is_failed { false }
    prize { 0 }

    # Фабрика :game создает объект Game без дочерних игровых вопросов, в такую
    # игру играть нельзя, поэтому мы расширяем эту фабрику, добавляя ещё одну:

    # Фабрика :game_with_questions наследует все поля от фабрики :game и
    # добавляет созданные вопросы.
    factory :game_with_questions do
      # Коллбэк: после того, как игра была создана (:build вызывается до
      # сохранения игры в базу), добавляем 15 вопросов разной сложности.
      after(:build) do |game|
        15.times do |level|
          question = create(:question, level: level)
          create(:game_question, game: game, question: question)
        end
      end
    end
  end
end
