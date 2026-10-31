require "html-proofer"

module LinkCheck
  SITE_URL = %r{\Ahttps://blog\.skelz0r\.fr}
  UNCHECKABLE_HOSTS = %r{\Ahttps?://([a-z0-9-]+\.)*(x\.com|twitter\.com|linkedin\.com|reddit\.com|news\.ycombinator\.com|buttondown\.com)(/|\z)}

  module_function

  def run(directory, external: true)
    HTMLProofer.check_directory(directory, options(external)).run
  end

  def options(external)
    {
      checks: %w[Links Images Scripts OpenGraph Favicon],
      disable_external: !external,
      enforce_https: true,
      ignore_empty_alt: false,
      ignore_missing_alt: false,
      allow_missing_href: false,
      swap_urls: {SITE_URL => ""},
      ignore_urls: [UNCHECKABLE_HOSTS, %r{/stats/script\.js\z}],
      cache: {timeframe: {external: "7d"}, storage_dir: "tmp/htmlproofer"},
      typhoeus: {followlocation: true, connecttimeout: 10, timeout: 20, headers: {"User-Agent" => "blog.skelz0r.fr link check"}},
      hydra: {max_concurrency: 8},
      log_level: :info
    }
  end
end
