require "uri"

class ShareKit
  URL_PLACEHOLDER = "{url}"
  TWEET_LIMIT = 280
  TWEET_URL_WEIGHT = 23
  URL_PATTERN = %r{https?://\S+}
  LINK_HINTS = [URL_PATTERN, /\{url\}/, /blog\.skelz0r\.fr/].freeze

  attr_reader :data, :article_url

  def initialize(article_url:, data:)
    @article_url = article_url
    @data = data || {}
  end

  def self.ref_url(article_url, ref)
    uri = URI(article_url)
    uri.query = URI.encode_www_form(URI.decode_www_form(uri.query.to_s) + [["ref", ref]])
    uri.to_s
  end

  def self.reddit_ref(subreddit)
    "reddit-#{subreddit.to_s.downcase.delete_prefix("r/")}"
  end

  def self.tweet_length(text)
    text.to_s.gsub(URL_PATTERN, "x" * TWEET_URL_WEIGHT).each_grapheme_cluster.count
  end

  def url_for(ref) = self.class.ref_url(article_url, ref)

  def fill(text, ref) = text.to_s.gsub(URL_PLACEHOLDER, url_for(ref))

  def hn
    section = data["hn"] || {}
    return if section.empty?

    title = section["title"].to_s
    title = "Show HN: #{title}" if section["show_hn"] && !title.start_with?("Show HN")
    url = url_for("hn")
    {title: title, url: url, submit: "https://news.ycombinator.com/submitlink?#{URI.encode_www_form(u: url, t: title)}"}
  end

  def tweets
    thread = [*data.dig("x", "thread")]
    reply = data.dig("x", "link_reply")
    posts = thread.each_with_index.map { |text, index| {label: "Tweet #{index + 1}", text: fill(text, "x")} }
    posts << {label: "Link, as a reply to tweet 1", text: fill(reply, "x")} if reply
    posts.map { |post| post.merge(length: self.class.tweet_length(post[:text])) }
  end

  def x_visual = data.dig("x", "visual")

  def x_article = data["x_article"] && fill(data["x_article"], "x")

  def reddit_posts
    [*data["reddit"]].map do |post|
      subreddit = post["subreddit"].to_s.delete_prefix("r/")
      ref = self.class.reddit_ref(subreddit)
      {
        subreddit: subreddit,
        title: post["title"].to_s,
        body: fill(post["body"], ref),
        url: url_for(ref),
        rules: "https://www.reddit.com/r/#{subreddit}/about/rules",
        submit: "https://www.reddit.com/r/#{subreddit}/submit?#{URI.encode_www_form(type: "TEXT", title: post["title"].to_s)}"
      }
    end
  end

  def newsletter_subject = data["newsletter_subject"]

  def problems
    list = []
    hook = [*data.dig("x", "thread")].first.to_s
    list << "x.thread[0] contains a link: put it in x.link_reply" if LINK_HINTS.any? { |pattern| hook.match?(pattern) }
    tweets.each { |post| list << "#{post[:label]} is #{post[:length]} characters (max #{TWEET_LIMIT})" if post[:length] > TWEET_LIMIT }
    list << "hn.title is longer than 80 characters" if hn && hn[:title].length > 80
    list
  end
end
