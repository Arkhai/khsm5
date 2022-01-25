require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe GamesController, type: :controller do
  # обычный пользователь
  let(:user) { FactoryBot.create(:user) }
  # админ
  let(:admin) { FactoryBot.create(:user, is_admin: true) }
  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  describe '#show' do
    context 'Anonimus user' do
      # Аноним не может смотреть игру
      it 'kicks from #show' do
        # Вызываем экшен
        get :show, params: {id: game_w_questions.id}
        # Проверяем ответ
        # статус ответа не равен 200
        expect(response.status).not_to eq(200)
        # Devise должен отправить на логин
        expect(response).to redirect_to(new_user_session_path)
        # Во flash должно быть сообщение об ошибке
        expect(flash[:alert]).to be
      end
    end

    context 'when authenticated user' do
      it 'show game' do
        sign_in user
        # Показываем по GET-запросу
        get :show, params: {id: game_w_questions.id}
        # Вытаскиваем из контроллера поле @game
        game = assigns(:game)
        # Игра не закончена
        expect(game.finished?).to be_falsey
        # Юзер именно тот, которого залогинили
        expect(game.user).to eq(user)

        # Проверяем статус ответа (200 ОК)
        expect(response.status).to eq(200)
        # Проверяем рендерится ли шаблон show (НЕ сам шаблон!)
        expect(response).to render_template('show')
      end

      it 'kicks from alien game' do
        sign_in user
        # создаем новую игру, юзер не прописан, будет создан фабрикой новый
        alien_game = FactoryBot.create(:game_with_questions)

        # пробуем зайти на эту игру текущий залогиненным user
        get :show, params: {id: alien_game.id}

        expect(response.status).not_to eq(200) # статус не 200 ОК
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be # во flash должен быть прописана ошибка
      end
    end
  end

  describe '#create' do
    context 'Anonimus user' do
      it 'kicks from #create' do
        expect { post :create }.to change(Game, :count).by(0)

        game = assigns(:game) # вытаскиваем из контроллера поле @game
        expect(game).to be_nil

        expect(response.status).not_to eq(200)
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be
      end
    end

    context 'when authenticated user' do
      it 'creates game' do
        sign_in user
        # Создадим пачку вопросов
        generate_questions(15)

        # Экшен create у нас отвечает на запрос POST
        post :create
        # Вытаскиваем из контроллера поле @game
        game = assigns(:game)

        # Проверяем состояние этой игры: она не закончена
        # Юзер должен быть именно тот, которого залогинили
        expect(game.finished?).to be_falsey
        expect(game.user).to eq(user)
        # Проверяем, есть ли редирект на страницу этой игры
        # И есть ли сообщение об этом
        expect(response).to redirect_to(game_path(game))
        expect(flash[:notice]).to be
      end

      # юзер пытается создать новую игру, не закончив старую
      it 'kicks from creating second game' do
        sign_in user
        # убедились что есть игра в работе
        expect(game_w_questions.finished?).to be_falsey

        # отправляем запрос на создание, убеждаемся что новых Game не создалось
        expect { post :create }.to change(Game, :count).by(0)

        game = assigns(:game) # вытаскиваем из контроллера поле @game
        expect(game).to be_nil

        # и редирект на страницу старой игры
        expect(response).to redirect_to(game_path(game_w_questions))
        expect(flash[:alert]).to be
      end
    end
  end

  describe '#answer' do
    context 'Anonimus user' do
      it 'kicks from #answer' do
        put :answer, params: {id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key}

        expect(response.status).not_to eq(200)
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be
      end
    end

    context 'when authenticated user' do
      context 'and answer is correct' do
        it 'continues game' do
          sign_in user
          # Дёргаем экшен answer, передаем параметр params[:letter]
          put :answer, params: {id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key}
          game = assigns(:game)

          # Игра не закончена
          expect(game.finished?).to be_falsey
          # Уровень больше 0
          expect(game.current_level).to be > 0

          # Редирект на страницу игры
          expect(response).to redirect_to(game_path(game))
          # Флеш пустой
          expect(flash.empty?).to be_truthy
        end
      end

      context 'and answer is wrong' do
        it 'finishes game with fail' do
          sign_in user
          put :answer, params: {id: game_w_questions.id, letter: 'a'}
          game = assigns(:game)

          expect(game.finished?).to be_truthy
          expect(response).to redirect_to(user_path(user))
          expect(flash[:alert]).to be
        end
      end
    end
  end

  describe '#take_money' do
    context 'Anonimus user' do
      it 'kicks from #take_money' do
        put :take_money, params: {id: game_w_questions.id}

        expect(response.status).not_to eq(200)
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be
      end
    end

    context 'when authenticated user' do
      it 'reloads balance' do
        sign_in user
        # вручную поднимем уровень вопроса до выигрыша 200
        game_w_questions.update_attribute(:current_level, 2)

        put :take_money, params: {id: game_w_questions.id}
        # Вытаскиваем из контроллера поле @game
        game = assigns(:game)
        expect(game.finished?).to be_truthy
        expect(game.prize).to eq(200)

        # пользователь изменился в базе, надо в коде перезагрузить!
        user.reload
        expect(user.balance).to eq(200)

        expect(response).to redirect_to(user_path(user))
        expect(flash[:warning]).to be
      end
    end
  end

  describe '#help' do
    context 'when authenticated user' do
      it 'uses audience help' do
        sign_in user
        # Проверяем, что у текущего вопроса нет подсказок
        expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
        # И подсказка не использована
        expect(game_w_questions.audience_help_used).to be_falsey

        # Пишем запрос в контроллер с нужным типом (put — не создаёт новых сущностей, но что-то меняет)
        put :help, params: {id: game_w_questions.id, help_type: :audience_help}
        game = assigns(:game)

        # Проверяем, что игра не закончилась, что флажок установился, и подсказка записалась
        expect(game.finished?).to be_falsey
        expect(game.audience_help_used).to be_truthy
        expect(game.current_game_question.help_hash[:audience_help]).to be
        expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
        expect(response).to redirect_to(game_path(game))
      end
    end
  end
end
