Bridgetown.configure do |config|
  url "https://blog.skelz0r.fr"
  template_engine "erb"
  timezone "Europe/Paris"

  collections do
    posts do
      permalink "/:slug/"
    end
  end

  init :"bridgetown-feed"
  init :"bridgetown-sitemap"
end
