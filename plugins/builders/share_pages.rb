require_relative "../../lib/share_kit"

class Builders::SharePages < SiteBuilder
  def build
    return if site.config.site_target == "production"

    generator do
      site.collections.posts.resources.each do |post|
        slug = post.data.slug
        add_resource :pages, "_share/#{slug}.erb" do
          layout "share"
          title "Share: #{post.data.title}"
          permalink "/_share/#{slug}/"
          share_slug slug
          noindex true
          sitemap false
          content ""
        end
      end
    end
  end
end
