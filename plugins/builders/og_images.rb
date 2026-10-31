require_relative "../../lib/og_image"

class Builders::OgImages < SiteBuilder
  HOME = "/og/home.png"

  def build
    hook :site, :post_read do |site|
      site.collections.posts.resources.each do |post|
        post.data.og_image = "/og/#{post.data.slug}.png"
      end
    end

    hook :site, :post_write do |site|
      cache_dir = File.join(site.cache_dir, "og")
      host = URI(site.config.url).host
      write = ->(path, image) { image.write(File.join(site.config.destination, path), cache_dir: cache_dir) }

      write.call(HOME, OgImage.new(title: site.metadata.tagline, footer: host))
      site.collections.posts.resources.each do |post|
        footer = "#{host}  ·  #{post.date.strftime("%B %-d, %Y")}"
        write.call(post.data.og_image, OgImage.new(title: post.data.title, footer: footer))
      end
    end
  end
end
