# (c) goodprogrammer.ru
#
# Объявление фабрики для создания нужных в тестах объектов
#
# См. другие примеры:
#
# http://www.rubydoc.info/gems/factory_girl/file/GETTING_STARTED.md
FactoryBot.define do
  factory :game_question do
    # Всегда одинаковое распределение ответов, в тестах удобнее детерминизм.
    a { 4 }
    b { 3 }
    c { 2 }
    d { 1 }

    # Связь с игрой и вопросом. Если при создании game_question не указать явно
    # объекты Игра и Вопрос, наша фабрика сама создаст и пропишет нужные
    # объекты, используя фабрики с именами :game и :question.
    association :game
    association :question
  end
end
