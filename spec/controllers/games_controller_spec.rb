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
      before { sign_in user }

      context 'audience help' do
        context 'audience help is not used' do
          it 'returns there is no help_hash' do
            expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
          end

          it 'returns audience help is not used' do
            expect(game_w_questions.audience_help_used).to eq false
          end
        end

        context 'audience help is used' do
          before do
            put :help, params: {id: game_w_questions.id, help_type: :audience_help}
          end

          let(:game) { assigns(:game) }

          it 'continues game' do
            expect(game.finished?).to eq false
          end

          it 'returns audience help is used' do
            expect(game.audience_help_used).to eq true
          end

          it 'creates help hash with audience help key' do
            expect(game.current_game_question.help_hash[:audience_help]).to be
          end

          it 'help hash returns correct keys' do
            expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
          end

          it 'redirects to game path' do
            expect(response).to redirect_to(game_path(game))
          end
        end
      end

      context 'fifty fifty' do
        context 'fifty fifty is not used' do
          it 'returns there is no help_hash' do
            expect(game_w_questions.current_game_question.help_hash[:fifty_fifty]).not_to be
          end

          it 'returns audience help is not used' do
            expect(game_w_questions.fifty_fifty_used).to eq false
          end
        end

        context 'fifty fifty is used' do
          before do
            put :help, params: {id: game_w_questions.id, help_type: :fifty_fifty}
          end

          let(:game) { assigns(:game) }

          it 'continues game' do
            expect(game.finished?).to eq false
          end

          it 'returns fifty fifty is used' do
            expect(game.fifty_fifty_used).to eq true
          end

          it 'creates help hash with fifty fifty key' do
            expect(game.current_game_question.help_hash[:fifty_fifty]).to be
          end

          it 'returns help hash contains correct answer' do
            expect(game.current_game_question.help_hash[:fifty_fifty]).to include('b')
          end

          it 'returns correct size of help hash' do
            expect(game.current_game_question.help_hash[:fifty_fifty].size).to eq 2
          end

          it 'redirects to game path' do
            expect(response).to redirect_to(game_path(game))
          end
        end
      end
    end
  end
end
