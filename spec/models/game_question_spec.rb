require 'rails_helper'

# Тестовый сценарий для модели игрового вопроса, в идеале весь наш функционал
# (все методы) должны быть протестированы.
RSpec.describe GameQuestion, type: :model do
  # Задаем локальную переменную game_question, доступную во всех тестах этого
  # сценария: она будет создана на фабрике заново для каждого блока it,
  # где она вызывается.
  let(:game_question) do
    FactoryBot.create(:game_question, a: 2, b: 1, c: 4, d: 3)
  end

  # Группа тестов на игровое состояние объекта вопроса
  describe '.variants' do
    # Тест на правильную генерацию хэша с вариантами
    it 'create correct variants' do
      expect(game_question.variants).to eq(
        'a' => game_question.question.answer2,
        'b' => game_question.question.answer1,
        'c' => game_question.question.answer4,
        'd' => game_question.question.answer3
      )
    end
  end

  describe '.answer_correct?' do
    it 'creates the right answer' do
      # Именно под буквой b в тесте мы спрятали указатель на верный ответ
      expect(game_question.answer_correct?('b')).to be_truthy
    end
  end

  describe '.correct_answer_key' do
    it 'sets the right answer key' do
      expect(game_question.correct_answer_key).to eq('b')
    end
  end

  describe '#delegate text and level to question' do
    it 'delegates .level & .text to question' do
      expect(game_question.text).to eq(game_question.question.text)
      expect(game_question.level).to eq(game_question.question.level)
    end
  end

  describe '#help_hash' do
    it 'correctly add help_hash' do
      # на фабрике у нас изначально хэш пустой
      expect(game_question.help_hash).to eq({})

      # добавляем пару ключей
      game_question.help_hash[:some_key1] = 'blabla1'
      game_question.help_hash[:some_key2] = 'blabla2'

      # сохраняем модель и ожидаем сохранения хорошего
      expect(game_question.save).to be_truthy

      # загрузим этот же вопрос из базы для чистоты эксперимента
      gq = GameQuestion.find(game_question.id)

      # проверяем новые значение хэша
      expect(gq.help_hash).to eq({ some_key1: 'blabla1', some_key2: 'blabla2' })
    end
  end

  describe '#add_audience_help' do
    context 'before using audience_help' do
      it 'returns empty hash' do
        expect(game_question.help_hash).not_to include(:audience_help)
      end
    end

    context 'added audience_help' do
      it 'returns not empty hash' do
        game_question.add_audience_help
        expect(game_question.help_hash).to include(:audience_help)
      end

      it 'returns correct keys' do
        game_question.add_audience_help
        ah = game_question.help_hash[:audience_help]
        expect(ah.keys).to contain_exactly('a', 'b', 'c', 'd')
      end
    end
  end

  describe '#add_fifty_fifty' do
    context 'before using fifty_fifty' do
      it 'returns empty hash' do
        expect(game_question.help_hash).not_to include(:fifty_fifty)
      end
    end

    context 'added fifty_fifty' do
      it 'returns not empty hash' do
        game_question.add_fifty_fifty
        expect(game_question.help_hash).to include(:fifty_fifty)
      end

      it 'returns correct key' do
        game_question.add_fifty_fifty
        expect(game_question.help_hash[:fifty_fifty]).to include('b') # должен остаться правильный вариант
      end

      it 'returns correct keys size' do
        game_question.add_fifty_fifty
        expect(game_question.help_hash[:fifty_fifty].size).to eq 2 # всего должно остаться 2 варианта
      end
    end
  end

  describe '#add_friend_call' do
    context 'before using friend_call' do
      it 'returns empty hash' do
        expect(game_question.help_hash).not_to include(:friend_call)
      end
    end

    context 'added friend_call' do
      it 'returns not empty hash' do
        game_question.add_friend_call
        expect(game_question.help_hash).to include(:friend_call)
      end

      it 'contains one key' do
        game_question.add_friend_call
        expect(game_question.help_hash[:friend_call]).to match(/[ABCD]/)
      end
    end
  end
end
