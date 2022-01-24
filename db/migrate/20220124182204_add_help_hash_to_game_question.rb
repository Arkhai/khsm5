class AddHelpHashToGameQuestion < ActiveRecord::Migration[5.2]
  def change
    add_column :game_questions, :help_hash, :text
  end
end
