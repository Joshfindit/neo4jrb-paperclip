# encoding: utf-8

begin
  require "paperclip"
rescue LoadError
  puts "Neo4j::Paperclip requires that you install the Paperclip gem."
  exit
end

##
# TODO
# Fix this
module Paperclip
  class << self
    # def logger
    #   Neo4j::Config[:logger]
    # end
  end
end


##
# The Neo4j::Paperclip extension
# Makes Paperclip play nice with the Neo4j Models
#
# Example:
#
#  class User
#    include Neo4j::ActiveNode
#    include Neo4j::Paperclip
#
#    has_neo4jrb_attached_file :avatar
#    validates_attachment_content_type :avatar, content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif"]
#  end
#
# The above example is all you need to do. This will load the Paperclip library into the User model
# and add the "has_neo4jrb_attached_file" class method. Provide this method with the same values as you would
# when using "vanilla Paperclip". The first parameter is a symbol [:field] and the second parameter is a hash of options [options = {}].
# Note that the validation must come after the call to :has_neo4jrb_attached_file.
#
# Unlike Paperclip for ActiveRecord, since MongoDB does not use "schema" or "migrations", Neo4j::Paperclip automatically adds the neccesary "fields"
# to your Model (MongoDB collection) when you invoke the "#has_neo4jrb_attached_file" method. When you invoke "has_neo4jrb_attached_file :avatar" it will
# automatially add the following fields:
#
#  field :avatar_file_name,    :type => String
#  field :avatar_content_type, :type => String
#  field :avatar_file_size,    :type => Fixnum
#  field :avatar_updated_at,   :type => DateTime
#
module Neo4j 
  module Paperclip
    extend ActiveSupport::Concern
    include ::Paperclip::Validators

    module ClassMethods

      ##
      # Adds after_commit
      def after_commit(*args, &block)
        options = args.pop if args.last.is_a? Hash
        if options
          case options[:on]
          when :create
            after_create(*args, &block)
          when :update
            after_update(*args, &block)
          when :destroy
            after_destroy(*args, &block)
          else
            after_save(*args, &block)
          end
        else
          after_save(*args, &block)
        end
      end

      ##
      # Adds Neo4j::Paperclip's "#has_neo4jrb_attached_file" class method to the model
      # which includes Paperclip and Paperclip::Glue in to the model. Additionally
      # it'll also add the required fields for Paperclip since MongoDB is schemaless and doesn't
      # have migrations.
      def has_neo4j_attached_file(field, options = {})

        ##
        # Include Paperclip and Paperclip::Glue for compatibility
        include ::Paperclip
        include ::Paperclip::Glue

        ##
        # Invoke Paperclip's #has_attached_file method and passes in the
        # arguments specified by the user that invoked Neo4j::Paperclip#has_neo4jrb_attached_file
        has_attached_file(field, options)

        ##
        # Define the necessary collection fields in Neo4jrb for Paperclip
        property :"#{field}_file_name",    type: String
        property :"#{field}_content_type", type: String
        property :"#{field}_file_size",    type: Integer
        property :"#{field}_updated_at",   type: DateTime
      end

      ##
      # This method is deprecated
      def has_attached_file(field, options = {})
        raise "Neo4j::Paperclip#has_attached_file is deprecated, " +
          "Use 'has_neo4j_attached_file' instead"
      end
    end
  end
end
