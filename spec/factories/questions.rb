# (c) goodprogrammer.ru
#
# Объявление фабрики для создания нужных в тестах объектов
#
# См. другие примеры на
#
# http://www.rubydoc.info/gems/factory_girl/file/GETTING_STARTED.md
FactoryBot.define do
  factory :question do
    # Последовательность уникальных текстов вопроса
    sequence(:text) { |n| "В каком году была космичесая одиссея #{n}?" }

    # Уровни генерим от 0 до 14 подряд
    sequence(:level) { |n| n % 15}

    # Ответы сделаем рандомными для красоты
    answer1 {"#{rand(2001)}"}
    answer2 {"#{rand(2001)}"}
    answer3 {"#{rand(2001)}"}
    answer4 {"#{rand(2001)}"}
  end
end

# PS: неплохой фильмец
#
# https://ru.wikipedia.org/wiki/Космическая_одиссея_2001_года
