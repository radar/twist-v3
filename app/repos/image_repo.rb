# frozen_string_literal: true

module Twist
  module Repos
    class ImageRepo < Twist::DB::Repo
      commands :create, :update, use: :default_timestamps

      def by_chapter(chapter_id)
        images.where(chapter_id: chapter_id).to_a
      end

      def find_or_create_image(chapter_id, filename, image_path, caption)
        image = images.where(
          chapter_id: chapter_id,
          filename: filename,
        ).limit(1).one

        if image
          updated_image = update_caption(image.id, caption)
          upload_image(image.id, image_path)
          return updated_image
        end

        create_image(chapter_id, filename, image_path, caption)
      end

      def create_image(chapter_id, filename, image_path, caption)
        image = create(
          caption: caption,
          chapter_id: chapter_id,
          filename: filename,
          status: 'processing',
        )

        upload_image(image.id, image_path)

        image
      end

      def update_caption(image_id, caption)
        images.where(id: image_id).update(caption: caption)
      end

      def update_image_data(image_id, image_data)
        images.where(id: image_id).update(image_data: image_data)
      end

      def processed(image_id)
        images.where(id: image_id).update(status: 'processed')
      end

      def upload_image(image_id, image_path)
        ImageWorker.perform_async(image_id, image_path)
      end
    end
  end
end
