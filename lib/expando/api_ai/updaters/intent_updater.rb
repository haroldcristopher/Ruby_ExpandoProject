require 'json'

module Expando::ApiAi::Updaters
  # Updates intent objects on Dialogflow based on the contents of Expando source files.
  class IntentUpdater < Base
    # Update the named entity on API.ai.
    #
    # @return [Hash] if request successful. This is the response body.
    # @return [VoxableApiAiRuby::RequestError] if request is in error.
    def update!
      # Create source file objects for each intent that needs to be updated.
      intent_files    = generate_intent_files(object_names)
      responses_files = generate_responses_files(object_names)
      entity_files    = generate_entity_files

      # Create intent objects for each intent source file.
      intents = generate_intents(intent_files, responses_files, entity_files)

      # Update each intent.
      intents.each { |intent| intent.update! }
    end

    private

      # Generate `Expando::SourceFiles::IntentFile` objects for each intent matching
      #   the passed `intent_names`, or for all intents in the directory if none passed.
      #
      # @param [Array<String>] intent_names The names of the intent files to update.
      #
      # @return [Array<Expando::SourceFiles::IntentFile>] The generated file objects.
      def generate_intent_files(intent_names = nil)
        # TODO: Throw an error when a non-existing intent is requested.

        # Get a list of all intent file names.
        intent_file_names = Dir.entries(intents_path)[2..-1]

        # If the intents to update have been specified...
        if intent_names && intent_names.any?
          # ...reduce the list of intent source file names only to those that
          # match the requested intents.
          intent_file_names.reject! do |file_name|
            intent_file_base_name = File.basename(file_name, '.*')
            !intent_names.include?(intent_file_base_name)
          end
        end

        # Generate an array of full file paths to the requested intent source files.
        intent_file_paths = intent_file_names.collect { |name| File.join(intents_path, name) }

        # Generate a list of Expando::SourceFiles::IntentFile objects for each intent.
        intent_file_paths.collect { |path| Expando::SourceFiles::IntentFile.new(path) }
      end

      # Generate `Expando::SourceFiles::ResponsesFile` objects for each intent matching
      #   the passed `intent_names`, or for all intents in the directory if none passed.
      #
      # @param [Array<String>] intent_names The names of the intent files to update.
      #
      # @return [Array<Expando::SourceFiles::ResponsesFile>] The generated file objects.
      def generate_responses_files(intent_names)
        return [] unless Dir.exists?(responses_path)

        # Get a list of all response file names.
        responses_file_names = Dir.entries(responses_path)[2..-1]

        # If the intents to update have been specified...
        if intent_names && intent_names.any?
          # ...reduce the list of intent responses file names only to those that
          # match the requested intents.
          responses_file_names.reject! do |file_name|
            responses_file_base_name = File.basename(file_name, '.*')
            !intent_names.include?(responses_file_base_name)
          end
        end

        # Generate an array of full file paths to the requested intent source files.
        responses_file_paths = responses_file_names.collect { |name| File.join(responses_path, name) }

        # Generate a list of Expando::SourceFiles::IntentFile objects for each intent.
        responses_file_paths.collect { |path| Expando::SourceFiles::ResponsesFile.new(path) }
      end

      # Generate `Expando::ApiAi::Intent` objects for each passed intent source file.
      #
      # @param [Array<Expando::SourceFiles::IntentFile>] intent_files
      #   The intent source files.
      # @param [Array<Expando::SourceFiles::ResponsesFile>] responses_files
      #   The intent responses source files.
      # @param [Array<Expando::SourceFiles::EntitiesFile>] entity_files
      #   The entity source files.
      #
      # @return [Array<Expando::ApiAi::Intent>] The generated intent objects.
      def generate_intents(intent_files, responses_files, entity_files)
        intent_files.collect do |intent_file|
          # Find a matching responses file for this intent file, if one exists.
          responses_file = responses_files.select do |responses_file|
            responses_file.intent_name == intent_file.intent_name
          end.first

          Expando::ApiAi::Objects::Intent.new(
            source_file:    intent_file,
            responses_file: responses_file,
            entity_files:   entity_files,
            api_client:     client
          )
        end
      end
  end
end

