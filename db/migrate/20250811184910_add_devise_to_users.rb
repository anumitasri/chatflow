# frozen_string_literal: true

class AddDeviseToUsers < ActiveRecord::Migration[7.2]
  def self.up
    # Add missing Devise columns only
    change_table :users do |t|
      # DO NOT re-add :email (it already exists)
      t.string   :encrypted_password, null: false, default: "" unless column_exists?(:users, :encrypted_password)

      # Recoverable
      t.string   :reset_password_token unless column_exists?(:users, :reset_password_token)
      t.datetime :reset_password_sent_at unless column_exists?(:users, :reset_password_sent_at)

      # Rememberable
      t.datetime :remember_created_at unless column_exists?(:users, :remember_created_at)

      # (leave Trackable/Confirmable/Lockable commented unless you need them)
    end

    # Make existing email Devise-friendly
    if column_exists?(:users, :email)
      change_column_default :users, :email, ""       # default ""
      change_column_null    :users, :email, false    # NOT NULL
    end

    # Indexes (add only if missing)
    add_index :users, :email, unique: true unless index_exists?(:users, :email)
    add_index :users, :reset_password_token, unique: true unless index_exists?(:users, :reset_password_token)
  end

  def self.down
    # Safe rollback of only what we added
    remove_index :users, :reset_password_token if index_exists?(:users, :reset_password_token)
    remove_index :users, :email if index_exists?(:users, :email)

    remove_column :users, :remember_created_at if column_exists?(:users, :remember_created_at)
    remove_column :users, :reset_password_sent_at if column_exists?(:users, :reset_password_sent_at)
    remove_column :users, :reset_password_token if column_exists?(:users, :reset_password_token)
    remove_column :users, :encrypted_password if column_exists?(:users, :encrypted_password)
  end
end
