require "minitest/autorun"
require_relative "../lib/share_kit"

class ShareKitTest < Minitest::Test
  ARTICLE = "https://blog.skelz0r.fr/my-article/"

  def kit(data) = ShareKit.new(article_url: ARTICLE, data: data)

  def test_hacker_news_link_is_tagged_ref_hn
    assert_equal "#{ARTICLE}?ref=hn", kit("hn" => {"title" => "A title"}).hn[:url]
  end

  def test_x_links_are_tagged_ref_x
    posts = kit("x" => {"thread" => ["Hook", "More"], "link_reply" => "Read it: {url}"}).tweets
    assert_equal "Read it: #{ARTICLE}?ref=x", posts.last[:text]
  end

  def test_each_subreddit_gets_its_own_ref
    posts = kit("reddit" => [{"subreddit" => "r/ExperiencedDevs", "title" => "T", "body" => "See {url}"}]).reddit_posts
    assert_equal "See #{ARTICLE}?ref=reddit-experienceddevs", posts.first[:body]
  end

  def test_a_link_in_the_first_tweet_is_flagged
    problems = kit("x" => {"thread" => ["Hook {url}"]}).problems
    assert_includes problems, "x.thread[0] contains a link: put it in x.link_reply"
  end

  def test_a_link_counts_23_characters_in_a_tweet
    assert_equal 4 + 23, ShareKit.tweet_length("See https://blog.skelz0r.fr/a-very-long-slug-that-goes-on/?ref=x")
  end

  def test_a_bare_blog_domain_in_the_first_tweet_is_flagged
    problems = kit("x" => {"thread" => ["Read blog.skelz0r.fr/my-article"]}).problems
    assert_includes problems, "x.thread[0] contains a link: put it in x.link_reply"
  end
end
