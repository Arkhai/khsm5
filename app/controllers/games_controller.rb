# (c) goodprogrammer.ru
#
# Основной игровой контроллер
# Создает новую игру, обновляет статус игры по ответам юзера, выдает подсказки
class GamesController < ApplicationController
  before_action :authenticate_user!

  # Проверка нет ли у залогиненного юзера начатой игры
  before_action :goto_game_in_progress!, only: [:create]

  # Загружаем игру из базы для текущего юзера
  before_action :set_game, except: [:create]

  # Проверка — если игра завершена, отправляем юзера на его профиль, где он
  # может увидеть статистику сыгранных игр.
  before_action :redirect_from_finished_game!, except: [:create]

  def show
    @game_question = @game.current_game_question
  end

  # Действие create создает новую игру и отправляет на действие show (основной
  # игровой экран) в случае успеха.
  def create
    begin
      # Создаем игру для залогиненного юзера
      @game = Game.create_game_for_user!(current_user)

      # Отправляемся на страницу игры
      redirect_to game_path(@game), notice: I18n.t(
        'controllers.games.game_created',
        created_at: @game.created_at
      )
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => ex
      # Если ошибка создания игры
      Rails.logger.error("Error creating game for user #{current_user.id}, " \
                         "msg = #{ex}. #{ex.backtrace}")

      # Отправляемся назад с алертом
      redirect_to :back, alert: I18n.t('controllers.games.game_not_created')
    end
  end

  # Действие answer принимает ответ на вопрос, единственный обязательный
  # параметр — params[:letter] — буква, которую выбрал игрок.
  def answer
    # Выясняем у игры, правильно ли оветили
    @answer_is_correct = @game.answer_current_question!(params[:letter])
    @game_question = @game.current_game_question

    unless @answer_is_correct
      # Если ответили неправильно, отправляем юзера на профиль с сообщением
      flash[:alert] = I18n.t(
        'controllers.games.bad_answer',
        answer: @game_question.correct_answer,
        prize: view_context.number_to_currency(@game.prize)
      )
    end

    if @game.finished?
      # Если игра закончилась, отправялем юзера на свой профиль
      redirect_to user_path(current_user)
    else
      # Иначе, обратно на экран игры
      redirect_to game_path(@game)
    end
  end

  # Действие take_money вызывается из шаблона, когда пользователь берет кнопку
  # «Взять деньги». Параметров нет, т.к. вся необходимая информация есть в базе.
  def take_money
    # Заканчиваем игру
    @game.take_money!

    # Отправялем пользователя на профиль с сообщение о выигрыше
    redirect_to user_path(current_user), flash: {
      warning: I18n.t(
        'controllers.games.game_finished',
        prize: view_context.number_to_currency(@game.prize)
      )
    }
  end

  private

  def redirect_from_finished_game!
    if @game.finished?
      redirect_to user_path(current_user), alert: I18n.t(
        'controllers.games.game_closed',
        game_id: @game.id
      )
    end
  end

  def goto_game_in_progress!
    # Вот нам и пригодился наш scope in_progress из модели Game
    game_in_progress = current_user.games.in_progress.first

    unless game_in_progress.blank?
      redirect_to game_path(game_in_progress), alert: I18n.t(
        'controllers.games.game_not_finished'
      )
    end
  end

  def set_game
    @game = current_user.games.find_by(id: params[:id])

    if @game.blank?
      # Если у current_user нет игры - посылаем
      redirect_to root_path, alert: I18n.t(
        'controllers.games.not_your_game'
      )
    end
  end
end
