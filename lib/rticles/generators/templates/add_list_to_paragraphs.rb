class AddListToParagraphs < ActiveRecord::Migration
  def self.up
    add_column :paragraphs, :list, :boolean
  end

  def self.down
    remove_column :paragraphs, :list
  end
end
