class PublicController < ApplicationController
  def main
    @pf_homepage_properties = Property.where(status: "available").includes(:account).latest.limit(6)
    @pf_homepage_posts = Post.active.latest.limit(3)

    @properties = Property.latest
    @posts = Post.active.latest
  end
end
