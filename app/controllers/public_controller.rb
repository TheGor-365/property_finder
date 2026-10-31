class PublicController < ApplicationController
  def main
    @properties = Property.latest
    @posts = Post.active.latest
  end
end
