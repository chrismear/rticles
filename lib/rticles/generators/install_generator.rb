module Rticles
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path('../templates', __FILE__)

      def self.next_migration_number(dirname)
        next_migration_number = current_migration_number(dirname) + 1
        ActiveRecord::Migration.next_migration_number(next_migration_number)
      end

      def create_migration
        migration_template 'create_documents_and_paragraphs.rb', 'db/migrate/create_documents_and_paragraphs.rb'
      end
    end
  end
end
