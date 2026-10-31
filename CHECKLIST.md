# Article checklist

Two levels. The mechanical one blocks the build; the judgment one is
checked locally before merging, by hand or by asking Claude Code to
review the article against this file. The channel rules are current
habits, to revise as the stats come in.

## 1. Mechanical (blocking, `bundle exec rake check`)

| Rule | Enforced by |
|---|---|
| Front matter has `title`, `description` (150-160 characters), `date`, `tags` (non-empty list) | `plugins/builders/front_matter_validation.rb` |
| An Open Graph image is generated for the article | `plugins/builders/og_images.rb`, verified by html-proofer's OpenGraph check |
| No dead link, internal or external, no broken anchor | `lib/link_check.rb` (html-proofer) |
| Every image has a non-empty `alt` | `lib/link_check.rb` (html-proofer) |

## 2. Judgment (local review)

Article:

- Title: precise, 70 characters or less, no clickbait (no "you won't
  believe", no curiosity gap, no superlative it cannot back).
- The thesis is stated in the first paragraph.
- One idea per article: anything that needs its own thesis is a
  separate article.
- Every figure or factual claim has a source (link or experiment
  described in the article).
- Code is tested: it runs as shown, versions are stated when they
  matter, output shown is real output.

Channels, checked against `src/_data/share/<slug>.yml`:

- Hacker News: factual title, the article's own title when it already
  is; `show_hn: true` only when readers can try something (repo, tool,
  demo).
- Reddit: one entry per subreddit chosen for this article. Respect each
  sub's rules (self-promotion ratio, flair, link posts allowed or not).
  Native text post that stands on its own, link at the end. Title
  written for that sub.
- X: first tweet is the hook, with no link. The link goes in
  `link_reply`, posted as a reply to the first tweet. One visual. 5 to
  10 tweets in total.
- Newsletter: the subject differs from the article title.

## Share file format

`src/_data/share/<slug>.yml`, rendered on previews at
`/_share/<slug>/`. `{url}` is replaced by the article URL tagged for
the channel (`?ref=hn`, `?ref=x`, `?ref=reddit-<subreddit>`).

```yaml
newsletter_subject: Subject line, distinct from the title
hn:
  title: Factual title
  show_hn: false
x:
  thread:
    - Hook, no link
    - Second tweet
  link_reply: "Full write-up: {url}"
  visual: og image, or a path to a screenshot
x_article: |
  Long-form version for X Articles, ends with {url}
reddit:
  - subreddit: ExperiencedDevs
    title: Title written for this sub
    body: |
      Native text post. Link at the end: {url}
```
