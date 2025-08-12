class CreateConversations < ActiveRecord::Migration[7.2]
  def change
    create_table :conversations do |t|
      t.string :title
      t.boolean :group

      t.timestamps
    end

    change_column_default :conversations, :group, from: nil, to: false
  end
end
