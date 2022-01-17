#  (c) goodprogrammer.ru
#
# Модель Пользователя
class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable, :recoverable,
    :validatable, :rememberable

  # Имя не пустое, email валидирует Devise
  validates :name, presence: true

  # Поле is_admin может быть только булевское (лож/истина), также запрещаем
  # ситуацию, когда в этом поле nil.
  validates :is_admin, inclusion: {in: [true, false]}, allow_nil: false

  # Это поле должно быть только целым числом, также запрещаем ситуацию, когда
  # в этом поле nil.
  validates :balance, numericality: {only_integer: true}, allow_nil: false

  # У юзера много игр, они удалятся из базы вместе с ним
  has_many :games, dependent: :destroy

  # Метод average_price просто рассчитывает средний выигрыш пользователя
  # по всем его играм.
  def average_prize
    (balance.to_f/games.count).round unless games.count.zero?
  end
end
