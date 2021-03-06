# encoding: utf-8
module Mongoid #:nodoc:
  module Commands
    class Save
      # Performs a save of the supplied +Document+, handling all associated
      # callbacks and validation.
      #
      # Options:
      #
      # doc: A +Document+ that is going to be persisted.
      #
      # Returns: +true+ if validation passes, +false+ if not.
      def self.execute(doc, validate = true)
        return false if validate && !doc.valid?
        doc.run_callbacks :save do
          parent = doc._parent
          doc.new_record = false
          saved = if parent
            Save.execute(parent, validate)
          else
            doc.collection.save(doc.raw_attributes, :safe => Mongoid.persist_in_safe_mode)
          end
          return false unless saved
        end
        return true
      end
    end
  end
end
