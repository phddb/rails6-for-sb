# frozen_string_literal: true

# Defers image processing to ImageProcessingTransformer or MiniMagickTransformer.
#
# Delete and call ImageProcessingTransformer directly when MiniMagickTransformer is removed.
module ActiveStorage
  module Transformers
    class ImageTransformer < Transformer
      def self.deferred_class
        if ActiveStorage.variant_processor
          begin
            require "image_processing"
          rescue LoadError
            ActiveSupport::Deprecation.warn <<~WARNING.squish
            Generating image variants will require the image_processing gem in Rails 6.1.
            Please add `gem 'image_processing', '~> 1.2'` to your Gemfile.
            WARNING

            ActiveStorage::Transformers::MiniMagickTransformer
          else
            ActiveStorage::Transformers::ImageProcessingTransformer
          end
        else
          ActiveStorage::Transformers::MiniMagickTransformer
        end
      end

      def self.accept?(blob)
        self.deferred_class.accept? blob
      end

      def initialize(transformations)
        @deferred = ImageTransformer.deferred_class.new(transformations)
      end

      def process(file, format:)
        @deferred.process(file, format: format)
      end
    end
  end
end
