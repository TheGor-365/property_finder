module ApplicationHelper
  def profile_picture(account, width = 100)
    thumb = account.image.present? ? account.image.thumb.url : "placeholder.jpg"
    image_tag thumb, width: width, class: "profile-pic img-circle"
  end

  # Never interpolate untrusted flash text into JavaScript or mark it html_safe.
  # Flash notifications are rendered as ordinary escaped HTML in layouts/_flash.
  def pf_page_title
    if controller_name == "properties" && action_name == "show" && @property
      "#{@property.name} — Property Finder"
    elsif controller_name == "posts" && action_name == "show" && @post
      "#{@post.title} — Property Finder Journal"
    elsif controller_name == "posts" && action_name == "latest"
      "Journal — Property Finder"
    elsif controller_name == "properties" && action_name == "index"
      "Browse properties — Property Finder"
    elsif controller_name == "dashboard" && action_name == "index"
      "Agent dashboard — Property Finder"
    elsif controller_name == "enquiries"
      "Private enquiries — Property Finder"
    else
      "Property Finder — Ruby on Rails portfolio demo"
    end
  end

  def pf_page_description
    if controller_name == "properties" && action_name == "show" && @property
      "Explore #{@property.name} in the Property Finder software demonstration. Illustrative listings are not verified real estate offers."
    elsif controller_name == "posts" && action_name == "show" && @post
      @post.summary.presence || "Read an educational real estate article in the Property Finder Ruby on Rails demonstration."
    elsif controller_name == "posts" && action_name == "latest"
      "Read practical property guides and educational articles from the Property Finder demonstration journal."
    else
      "Property Finder is a Ruby on Rails portfolio demonstration with fictional home listings, search, agent profiles and persistent enquiries."
    end
  end

  def pf_private_page?
    @show_sidebar.present? || devise_controller? ||
      controller_name.in?(%w[enquiries agent_messages admin])
  end
end
