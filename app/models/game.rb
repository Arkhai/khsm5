#  (c) goodprogrammer.ru
#
# Модельи игры — создается когда пользователь начинает новую игру. Хранит и
# обновляет состояние игры и отвечает за игровой процесс.
class Game < ActiveRecord::Base
  # Сначала несколько констант, задающих механику игры: денежные призы за каждый
  # вопрос, номера несгораемых уровней и временной лимит на одну игру.
  PRIZES = [100, 200, 300, 500, 1_000, 2_000, 4_000, 8_000, 16_000,
            32_000, 64_000, 125_000, 250_000, 500_000, 1_000_000].freeze
  FIREPROOF_LEVELS = [4, 9, 14].freeze
  TIME_LIMIT = 35.minutes

  # У игры есть игрок — пользователь, который начал эту игру
  belongs_to :user

  # Массив игровых вопросов для этой игры. 15 вопросов для 15-ти уровней, в
  # каждый из них мы будем брать произвольный вопрос из общей базы вопросов.
  has_many :game_questions, dependent: :destroy

  # У игры обязательно должен быть игрок
  validates :user, presence: true

  # Текущий уровень сложности вопроса: число от 0 до 14, это поле не можеть быть
  # nil.
  validates :current_level, numericality: {only_integer: true}, allow_nil: false

  # Выигрыш игрока — целое число, лежащее от нуля до максимального приза за игру
  validates :prize, presence: true, numericality: {
    greater_than_or_equal_to: 0, less_than_or_equal_to: PRIZES.last
  }

  # Scope — это метод класса, который возвращает из базы подмножество игр,
  # удовлетворяющих условию. В нашем случае, у которых поле finished_at пусто.
  #
  # http://guides.rubyonrails.org/active_record_querying.html#scopes
  scope :in_progress, -> { where(finished_at: nil) }

  # Метод класса create_game_for_user! создает игру с правильно созданными
  # игровыми вопросами. Или возвращает ошибку, если этого сделать не удалось.
  # Именно поэтому в его названии восклицательный знак — надо быть аккуратнее с
  # этим методом.
  def self.create_game_for_user!(user)
    # Обратите внимание, что все действия мы делаем единой транзакцией, если
    # где-то словим исключение, откатятся все изменения в базе.
    transaction do
      # Создаем игру для данного игрока
      game = create!(user: user)

      # Созданной игре добавляем ровно 15 новых игровых вопросов разного уровня
      Question::QUESTION_LEVELS.each do |level|
        # Достаем из базы один произвольный вопрос нужной сложности
        question = Question.where(level: level).order(Arel.sql('RANDOM()')).first

        # Перемешиваем ответы — цисла от 1 до 4
        answers = [1, 2, 3, 4].shuffle

        # Наконец, создаем нужный объект GameQuestion и цепляем его к игре
        game.game_questions.create!(
          question: question,
          a: answers.pop, b: answers.pop, c: answers.pop, d: answers.pop
        )
      end

      # Возвращаем игру
      game
    end
  end

  # Метод current_game_question возвращает текущий, еще неотвеченный вопрос игры
  def current_game_question
    game_questions.detect { |q| q.question.level == current_level }
  end

  # Метод previous_level возвращает число, равное предыдущему уровню сложности.
  # Обратите внимание, что этот метод возвращает -1 для новой игры.
  def previous_level
    current_level - 1
  end

  # Метод, который сообщает, закончена ли текущая игра. Возвращает true, если
  # у игры прописано поле :finished_at — время конца игры.
  def finished?
    finished_at.present?
  end

  # Метод time_out! проверяет текущее время и грохает игру + возвращает true
  # если время прошло.
  def time_out!
    if (Time.now - created_at) > TIME_LIMIT
      finish_game!(fire_proof_prize(previous_level), true)
      true
    end
  end

  # Основные игровые методы:

  # Метод answer_current_question возвращает
  #
  # * true, если ответ верный: текущая игра при этом обновляет свое состояние:
  #   меняется :current_level, :prize (если несгораемый уровень), поля
  #   :updated_at прописывается :finished_at если это был последний вопрос.
  #
  # * false, если 1) ответ неверный 2) время вышло 3) игра уже закончена ранее.
  #   В любом случае прописывается :finished_at, :prize (если несгораемый
  #   уровень), :updated_at.
  #
  # В качестве параметра letter в метод необходимо передать строку 'a','b','c'
  # или 'd'.
  def answer_current_question!(letter)
    # Законченную игру низя обновлять
    return false if time_out! || finished?

    # С помощью метода answer_correct? у текущего игрового вопроса проверяем,
    # правильно ли ответили на текущий вопрос.
    if current_game_question.answer_correct?(letter)

      # Если это был последний вопрос, заканчиваем игру методом finish_game!
      if current_level == Question::QUESTION_LEVELS.max
        self.current_level += 1
        finish_game!(PRIZES[Question::QUESTION_LEVELS.max], false)
      else
        # Если нет, сохраняем игру и идем дальше
        self.current_level += 1
        save!
      end

      true
    else
      # Если ответили неправильно, заканчиваем игру методом finish_game! и
      # возвращаем false.
      finish_game!(fire_proof_prize(previous_level), true)
      false
    end
  end

  # TODO: Дорогой ученик!
  #
  # Код метода ниже можно сократиь в 3 раза с помощью возможностей Ruby и Rails,
  # подумайте как и реализуйте. Помните о безопасности и входных данных!
  #
  # Вариант решения вы найдете в комментарии в конце файла, отвечающего за настройки
  # хранения сессий вашего приложения. Вот такой вот вам ребус :)
  #
  # Создает варианты подсказок для текущего игрового вопроса.
  # Возвращает true, если подсказка применилась успешно,
  # false если подсказка уже заюзана.
  #
  # help_type = :fifty_fifty | :audience_help | :friend_call
  def use_help(help_type)
    help_types = %i(fifty_fifty audience_help friend_call)
    help_type = help_type.to_sym
    raise ArgumentError.new('wrong help_type') unless help_types.include?(help_type)

     unless self["#{help_type}_used"]
       self["#{help_type}_used"] = true
       current_game_question.apply_help!(help_type)
       save
     end
  end

  # Метод take_money! записывает юзеру игровую сумму на счет и завершает игру,
  def take_money!
    # Из законченной или неначатой игры нечего брать
    return if time_out! || finished?

    # Заканчиваем игру, записав игроку приз из несгораемых сумм
    finish_game!(previous_level > -1 ? PRIZES[previous_level] : 0, false)
  end

  # Результат игры status, возвращает, одно из:
  #
  # :fail — игра проиграна из-за неверного вопроса
  # :timeout — игра проиграна из-за таймаута
  # :won — игра выиграна (все 15 вопросов покорены)
  # :money — игра завершена, игрок забрал деньги
  # :in_progress — игра еще идет
  def status
    return :in_progress unless finished?

    if is_failed
      # TODO: дорогой ученик! Если TIME_LIMIT в будущем изменится, статусы
      # старых, уже сыгранных игр могут измениться. Подумайте как это исправить!
      # Ответ найдете в файле настроек вашего тестового окружения.
      (finished_at - created_at) > TIME_LIMIT ? :timeout : :fail
    elsif current_level > Question::QUESTION_LEVELS.max
      :won
    else
      :money
    end
  end

  private

  # Метод finish_game! завершает игру. Он обновляет все нужные поля и начисляет
  # юзеру выигрыш.
  def finish_game!(amount = 0, failed = true)
    # Оборачиваем в транзакцию — игра заканчивается и баланс юзера пополняется
    # только вместе.
    transaction do
      self.prize = amount
      self.finished_at = Time.now
      self.is_failed = failed
      user.balance += amount
      save!
      user.save!
    end
  end

  # Метод fire_proof_prize по заданному уровню вопроса вычисляет вознаграждение
  # за ближайшую несгораемую сумму.
  def fire_proof_prize(answered_level)
    level = FIREPROOF_LEVELS.select { |x| x <= answered_level }.last
    level.present? ? PRIZES[level] : 0
  end
end
