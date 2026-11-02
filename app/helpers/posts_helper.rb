module PostsHelper
  EDITORIAL_ILLUSTRATIONS = %w[
    editorial/living-room.svg
    editorial/terrace.svg
    editorial/architecture.svg
  ].freeze

  def post_thumbnail_url(post)
    return post.image.thumb.url if post.image.present?

    asset_path(EDITORIAL_ILLUSTRATIONS[post.id.to_i % EDITORIAL_ILLUSTRATIONS.length])
  end
end
