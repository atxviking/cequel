module Cequel
  module SpecSupport
    # Provide database preparation behavior that is useful for
    # spec/test suites.
    #
    # Adding the following code to the bottom of one's
    # `spec_helper.rb` (below the `RSpec.configure` block) ensures a
    # clean and fully synced test db before each test run.
    #
    #     # one time database setup
    #     Cequel::SpecSupport::Preparation.setup_database(Rails.root + "app/models")
    class Preparation

      # Provision and sync the database for a spec run.
      #
      # @param [Array<String,Pathname>] module_dirs directories in
      #   which Cequel record classes reside. All files in these
      #   directories will be loaded before syncing the schema.
      def self.setup_database(*module_dirs)
        prep = new(module_dirs.flatten)

        prep.drop_keyspace
        prep.create_keyspace
        prep.sync_schema
      end

      def initialize(model_dirs=[])
        @model_dirs = model_dirs
      end

      # Ensure the current keyspace does not exist.
      #
      # @return [Preparation] self
      def drop_keyspace
        Cequel::Record.connection.schema.tap do |schema|
          schema.drop! if schema.exists?
        end

        self
      end

      # Ensure that the necessary keyspace exists.
      #
      # @return [Preparation] self
      def drop_keyspace
        Cequel::Record.connection.schema.tap do |schema|
          schema.drop! if schema.exists?
        end

        self
      end

      # Ensure that the necessary keyspace exists.
      #
      # @return [Preparation] self
      def create_keyspace
        Cequel::Record.connection.schema.tap do |schema|
          schema.create! unless schema.exists?
        end

        self
      end

      # Ensure that the necessary column families exist and match the
      # models.
      #
      # @return [Preparation] self
      def sync_schema
        record_classes.each do |a_record_class|
          begin
            a_record_class.synchronize_schema
          rescue Record::MissingTableNameError
            # It is obviously not a real record class if it doesn't have a table name.
            puts "Skipping anonymous record class w/o an explicit table name"
          end
          puts "Synchronized schema for #{a_record_class.name}"
        end

        self
      end

      protected

      attr_reader :model_dirs

      # @return [Array<Class>] all Cequel record classes
      def record_classes
        load_all_models

        ObjectSpace.each_object(Class)
          .select {|an_obj| begin
                              Cequel::Record > an_obj
                            rescue TypeError=> e
                              # something was masquerading as a class but wasn't really.
                              false
                            end }
      end

      # Loads all files in the models directory under the assumption
      # that Cequel record classes live there.
      def load_all_models
        model_dirs.each do |a_directory|
          Dir.glob(Pathname(a_directory).join("**", "*.rb")).each do |file_name|
            require_dependency(file_name)
          end
        end
      end
    end
  end
end
