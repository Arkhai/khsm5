# Стандартный rspec-овский помощник для rails-проекта
require 'rails_helper'

# Наш собственный класс с вспомогательными методами
require 'support/my_spec_helper'

# Тестовый сценарий для модели Игры
#
# В идеале — все методы должны быть покрыты тестами, в этом классе содержится
# ключевая логика игры и значит работы сайта.
RSpec.describe Game, type: :model do
  # Пользователь для создания игр
  let(:user) { FactoryBot.create(:user) }

  # Игра с прописанными игровыми вопросами
  let(:game_w_questions) do
    FactoryBot.create(:game_with_questions, user: user)
  end

  # Группа тестов на работу фабрики создания новых игр
  describe '.create_game_for_user!' do
    context 'Game Factory' do
      it 'creates new correct game' do
        # Генерим 60 вопросов с 4х запасом по полю level, чтобы проверить работу
        # RANDOM при создании игры.
        generate_questions(60)

        game = nil

        # Создaли игру, обернули в блок, на который накладываем проверки
        expect {
          game = Game.create_game_for_user!(user)
          # Проверка: Game.count изменился на 1 (создали в базе 1 игру)
        }.to change(Game, :count).by(1).and(
          # GameQuestion.count +15
          change(GameQuestion, :count).by(15).and(
            # Game.count не должен измениться
            change(Question, :count).by(0)
          )
        )

        # Проверяем статус и поля
        expect(game.user).to eq(user)
        expect(game.status).to eq(:in_progress)

        # Проверяем корректность массива игровых вопросов
        expect(game.game_questions.size).to eq(15)
        expect(game.game_questions.map(&:level)).to eq (0..14).to_a
      end
    end
  end

  # Тесты на основную игровую логику
  context 'game mechanics' do
    # Правильный ответ должен продолжать игру
    it 'answer correct continues game' do
      # Текущий уровень игры и статус
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)

      # Перешли на след. уровень
      expect(game_w_questions.current_level).to eq(level + 1)

      # Ранее текущий вопрос стал предыдущим
      expect(game_w_questions.current_game_question).not_to eq(q)

      # Игра продолжается
      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be_falsey
    end

    it 'take_money! finishes the game' do
      question = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(question.correct_answer_key)

      game_w_questions.take_money!
      prize = game_w_questions.prize

      expect(game_w_questions.status).to eq(:money)
      expect(game_w_questions.finished?).to be_truthy
      expect(prize).to be > 0
      expect(user.balance).to eq prize
    end
  end

  describe '.current_game_question' do
    it 'returns correct game question' do
      expect(game_w_questions.current_game_question).to eq(game_w_questions.game_questions.first)
    end
  end

  describe '.previous_level' do
    it 'returns correct games previous level' do
      game_w_questions.current_level = 12
      expect(game_w_questions.previous_level).to eq 11
    end
  end

  describe '.answer_current_question!' do
    let(:question) { game_w_questions.current_game_question }

    context 'when right answer is given' do
      it 'increase game level' do
        level = game_w_questions.current_level
        game_w_questions.answer_current_question!(question.correct_answer_key)
        expect(game_w_questions.current_level).to eq(level + 1)
      end
    end

    context 'when right answer is given on the last level' do
      before do
        game_w_questions.current_level = Question::QUESTION_LEVELS.max
        game_w_questions.answer_current_question!(question.correct_answer_key)
      end

      it 'finishes the game' do
        expect(game_w_questions.finished?).to be_truthy
      end

      it 'set :won status' do
        expect(game_w_questions.status).to eq(:won)
      end

      it 'set the biggest prize' do
        expect(game_w_questions.prize).to eq(Game::PRIZES[Question::QUESTION_LEVELS.max])
      end

      it 'increase user balance on the correct amount' do
        expect(user.balance).to eq(Game::PRIZES[Question::QUESTION_LEVELS.max])
      end
    end

    context 'when right answer is given after timeout' do
      it 'returns false' do
        game_w_questions.finished_at = Time.now
        game_w_questions.created_at = 1.hour.ago
        expect(game_w_questions.answer_current_question!(question.correct_answer_key)).to be_falsey
      end
    end

    context 'incorrect answer given' do
      it 'return false for incorrect answer' do
        expect(game_w_questions.answer_current_question!('a')).to be_falsey
      end

      it 'sets game status to failed' do
        game_w_questions.answer_current_question!('a')
        expect(game_w_questions.status).to eq(:fail)
      end
    end
  end

  describe '.status' do
    before(:each) do
      game_w_questions.finished_at = Time.now
      expect(game_w_questions.finished?).to be_truthy
    end

    context 'when game is won' do
      it 'sets game status to :won' do
        game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
        expect(game_w_questions.status).to eq(:won)
      end
    end

    context 'when game is timeouted' do
      it 'sets game status to :timeout' do
        game_w_questions.created_at = 1.hour.ago
        game_w_questions.is_failed = true
        expect(game_w_questions.status).to eq(:timeout)
      end
    end

    context 'when game is failed' do
      it 'sets game status to fail' do
        game_w_questions.is_failed = true
        expect(game_w_questions.status).to eq(:fail)
      end
    end

    context 'when player took money' do
      it 'sets game status to :money' do
        expect(game_w_questions.status).to eq(:money)
      end
    end
  end
end
