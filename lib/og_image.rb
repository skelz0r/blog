require "cgi"
require "digest"
require "fileutils"
require "vips"

class OgImage
  WIDTH = 1200
  HEIGHT = 630
  MARGIN = 80
  BACKGROUND = [21, 23, 26].freeze
  FONTS = File.expand_path("../assets/fonts", __dir__)
  TITLE_SIZES = [76, 68, 60, 52, 46].freeze
  TITLE_MAX_HEIGHT = 330
  VERSION = 1

  def initialize(title:, footer:, kicker: "skelz0r")
    @title = title.to_s
    @footer = footer.to_s
    @kicker = kicker
  end

  def cache_key
    Digest::SHA256.hexdigest([VERSION, @title, @footer, @kicker].join("\0"))
  end

  def write(path, cache_dir:)
    cached = File.join(cache_dir, "#{cache_key}.png")
    unless File.exist?(cached)
      FileUtils.mkdir_p(cache_dir)
      render.write_to_file(cached)
    end
    FileUtils.mkdir_p(File.dirname(path))
    FileUtils.cp(cached, path)
  end

  def render
    canvas = Vips::Image.black(WIDTH, HEIGHT, bands: 3).new_from_image(BACKGROUND).copy(interpretation: :srgb)
    canvas = paste(canvas, text(@kicker, "Inter Bold 30", "#7cb7ff"), MARGIN, MARGIN)
    title = fitted_title
    canvas = paste(canvas, title, MARGIN, (HEIGHT - title.height) / 2)
    footer = text(@footer, "Inter 28", "#9da3ab")
    paste(canvas, footer, MARGIN, HEIGHT - MARGIN - footer.height)
  end

  private

  def fitted_title
    TITLE_SIZES.each do |size|
      image = text(@title, "Inter Bold #{size}", "#e6e4df", spacing: size / 5)
      return image if image.height <= TITLE_MAX_HEIGHT
    end
    text(@title, "Inter Bold #{TITLE_SIZES.last}", "#e6e4df", spacing: 8)
  end

  def text(content, font, color, spacing: 0)
    Vips::Image.text(
      %(<span foreground="#{color}">#{CGI.escapeHTML(content)}</span>),
      font: font,
      fontfile: font_file(font),
      width: WIDTH - 2 * MARGIN,
      spacing: spacing,
      dpi: 72,
      rgba: true
    )
  end

  def font_file(font)
    File.join(FONTS, font.include?("Bold") ? "Inter-Bold.ttf" : "Inter-Regular.ttf")
  end

  def paste(canvas, overlay, x, y)
    canvas.composite2(overlay, :over, x: x, y: y).flatten.cast(:uchar)
  end
end
