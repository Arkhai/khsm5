# (c) goodprogrammer.ru

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

  describe '#delegate' do
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
      expect(gq.help_hash).to eq({some_key1: 'blabla1', some_key2: 'blabla2'})
    end
  end

  describe '#apply_help!' do
    context 'user uses help' do
      it 'correct audience_help' do
        expect(game_question.help_hash).not_to include(:audience_help)

        game_question.add_audience_help

        expect(game_question.help_hash).to include(:audience_help)

        ah = game_question.help_hash[:audience_help]
        expect(ah.keys).to contain_exactly('a', 'b', 'c', 'd')
      end

      it 'correct fifty_fifty' do
        # сначала убедимся, в подсказках пока нет нужного ключа
        expect(game_question.help_hash).not_to include(:fifty_fifty)
        # вызовем подсказку
        game_question.add_fifty_fifty

        # проверим создание подсказки
        expect(game_question.help_hash).to include(:fifty_fifty)
        ff = game_question.help_hash[:fifty_fifty]

        expect(ff).to include('b') # должен остаться правильный вариант
        expect(ff.size).to eq 2 # всего должно остаться 2 варианта
      end
    end
  end
end
