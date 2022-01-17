#  (c) goodprogrammer.ru
#
# Игровой вопрос — модель, которая связывает игру и вопрос. При создании новой
# игры формируется массив из 15 игровых вопросов для конкретной игры.
class GameQuestion < ActiveRecord::Base
  # Игровой вопрос, конечно, принадлежит конкретной игре.
  belongs_to :game

  # Игровой вопрос знает, из какого вопроса берется информация
  belongs_to :question

  # Создаем в этой модели виртуальные геттеры text, level, значения которых
  # автоматически берутся из связанной модели question.
  #
  # Таким обазом при вызове, например
  #
  # game_question.text
  #
  # получим то, что лежит в
  #
  # game_question.question.text
  #
  delegate :text, :level, to: :question, allow_nil: true

  # Без игры и вопроса — игровой вопрос не имеет смысла
  validates :game, :question, presence: true

  # В полях a, b, c и d прячутся индексы ответов из объекта :game. Каждый из
  # них — целое число от 1 до 4.
  validates :a, :b, :c, :d, inclusion: {in: 1..4}

  # Основные методы для доступа к данным в шаблонах и контроллерах:

  # Метод variants возвращает хэш с ключами a..d и значениями — тектом ответов:
  #
  # {
  #   'a' => 'Текст ответа Х',
  #   'b' => 'Текст ответа У',
  #   ...
  # }
  def variants
    {
      'a' => question.read_attribute("answer#{a}"),
      'b' => question.read_attribute("answer#{b}"),
      'c' => question.read_attribute("answer#{c}"),
      'd' => question.read_attribute("answer#{d}")
    }
  end

  # Метод answer_correct? проверяет правильность ответа по букве. Возвращает
  # true, если переданная буква (строка или символ) содержит верный ответ и
  # false во всех других случаях.
  def answer_correct?(letter)
    correct_answer_key == letter.to_s.downcase
  end

  # Метод correct_answer_key возвращает ключ правильного ответа 'a', 'b', 'c',
  # или 'd'. Обратите внимание, что в переменных a, b, c и d игрового вопроса
  # лежат числа от 1 до 4, но мы не знаем, в какой букве какое число.
  def correct_answer_key
    {a => 'a', b => 'b', c => 'c', d => 'd'}[1]
  end

  # Метод correct_answer возвращает текст правильного ответа
  def correct_answer
    variants[correct_answer_key]
  end
end
