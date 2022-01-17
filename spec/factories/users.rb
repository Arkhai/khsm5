# (c) goodprogrammer.ru
#
# Объявление фабрики для создания нужных в тестах объектов
#
# См. другие примеры на
#
# http://www.rubydoc.info/gems/factory_girl/file/GETTING_STARTED.md
FactoryBot.define do
  # Фабрика, создающая юзеров
  factory :user do
    # Генерим рандомное имя
    name { "Жора_#{rand(999)}" }

    # email должен быть уникален — при каждом вызове фабрики n будет увеличен
    # поэтому все юзеры будут иметь разные адреса: someguy_1@example.com,
    # someguy_2@example.com, someguy_3@example.com ...
    sequence(:email) { |n| "someguy_#{n}@example.com" }

    # Всегда создается с флажком false, ничего не генерим
    is_admin { false }

    # Всегда нулевой
    balance { 0 }

    # Коллбэк — после фазы :build записываем поля паролей, иначе Devise не
    # позволит создать юзера
    after(:build) { |u| u.password_confirmation = u.password = "123456"}
  end
end
