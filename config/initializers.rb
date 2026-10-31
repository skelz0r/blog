Bridgetown.configure do |config|
  url "https://blog.skelz0r.fr"
  template_engine "erb"
  timezone "Europe/Paris"

  collections do
    posts do
      permalink "/:slug/"
    end
  end

  config.site_target = ENV.fetch("SITE_TARGET", "local")
  config.umami_script_url = ENV["UMAMI_SCRIPT_URL"]
  config.umami_website_id = ENV["UMAMI_WEBSITE_ID"]

  init :"bridgetown-feed"
  init :"bridgetown-sitemap"
end
