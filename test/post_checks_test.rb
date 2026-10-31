require "minitest/autorun"
require "tmpdir"
require_relative "../lib/post_checks"

class PostChecksTest < Minitest::Test
  def problems_for(front_matter)
    Dir.mktmpdir do |dir|
      path = File.join(dir, "post.md")
      File.write(path, "---\n#{front_matter}\n---\n\nBody\n")
      PostChecks.front_matter_problems(path)
    end
  end

  def complete(description: "d" * 155, tags: "[ai, tooling]")
    "title: A title\ndescription: #{description}\ndate: 2026-11-02\ntags: #{tags}"
  end

  def test_a_complete_front_matter_is_accepted
    assert_empty problems_for(complete)
  end

  def test_a_description_between_150_and_160_characters_is_accepted
    assert_empty problems_for(complete(description: "d" * 150))
    assert_empty problems_for(complete(description: "d" * 160))
  end

  def test_a_description_shorter_than_150_or_longer_than_160_characters_is_refused
    assert_equal ["description is 149 characters, expected 150-160"], problems_for(complete(description: "d" * 149))
    assert_equal ["description is 161 characters, expected 150-160"], problems_for(complete(description: "d" * 161))
  end

  def test_an_article_without_tags_is_refused
    assert_equal ["tags must be a non-empty list"], problems_for(complete(tags: "[]"))
    assert_equal ["tags must be a non-empty list"], problems_for(complete(tags: "ai"))
  end

  def test_every_missing_field_is_reported
    assert_equal ["title is missing", "description is missing", "date is missing", "tags must be a non-empty list"],
      problems_for("layout: post")
  end
end
