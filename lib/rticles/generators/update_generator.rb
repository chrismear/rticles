module Rticles
  module Generators
    class UpdateGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path('../templates', __FILE__)

      def self.next_migration_number(dirname)
        next_migration_number = current_migration_number(dirname) + 1
        ActiveRecord::Migration.next_migration_number(next_migration_number)
      end

      def create_migration
        migration_template 'add_list_to_paragraphs.rb', 'db/migrate/add_list_to_paragraphs.rb'
      end
    end
  end
end
