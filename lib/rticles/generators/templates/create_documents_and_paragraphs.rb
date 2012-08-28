class CreateDocumentsAndParagraphs < ActiveRecord::Migration
  def self.up
    create_table :documents do |t|
      t.string 'title'
      t.timestamps
    end
    create_table :paragraphs do |t|
      t.text 'body'
      t.integer 'position'
      t.integer 'parent_id'
      t.integer 'document_id'
      t.integer 'heading'
      t.boolean 'continuation'
      t.string 'name'
      t.string 'topic'
      t.timestamps
    end
  end

  def self.down
    drop_table :paragraphs
    drop_table :documents
  end
end
