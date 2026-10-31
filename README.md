# blog.skelz0r.fr

Tech, agentic coding, software engineering in the age of AI. Articles are
written by a human; AI helps proofread them, it does not write them.

Built with [Bridgetown](https://www.bridgetownrb.com), deployed on
Cloudflare Pages by GitHub Actions.

## Editorial workflow

1. **Idea**: an issue from the "Article idea" template (label `idea`):
   thesis, audience, material.
2. **Draft**: `bin/new-post <slug>`, write `src/_posts/<slug>.md`, open a
   draft pull request with `Closes #<issue>`. Repository and drafts are
   public.
3. **Review**: every push deploys a preview and comments its URL. Review
   the article locally against [`CHECKLIST.md`](CHECKLIST.md) (by hand or
   with Claude Code) and write `src/_data/share/<slug>.yml`.
4. **Publish**: merge. Production deploys only if the build checks pass,
   then a newsletter draft is created in Buttondown.
5. **Share**: open `/_share/<slug>/` on the PR preview, copy the posts,
   publish by hand on HN, Reddit and X.
6. **Measure**: `bin/stats <slug>`.

## Commands

| Command | What it does |
|---|---|
| `bin/bridgetown start` | Dev server on http://localhost:4000, share pages included, front matter problems as warnings |
| `bundle exec rake check` | Production build (front matter must be valid), then links, images, alt texts |
| `SKIP_EXTERNAL_LINKS=1 bundle exec rake check` | Same, offline |
| `bundle exec rake test` | Tests of the checks themselves |
| `bin/new-post <slug>` | New article with an empty front matter |
| `bin/newsletter-draft --dry-run <slug>` | Show the Buttondown draft that will be created |
| `bin/stats [--days N] <slug>` | Views by channel (`?ref=`) from Umami |

Requires Ruby (see `.ruby-version`) and libvips (`brew install vips`) for
the Open Graph images.

## Build targets

`SITE_TARGET` decides what goes into the build:

| Target | Share pages | Umami |
|---|---|---|
| `local` (default) | yes | no |
| `preview` | yes | no |
| `production` | no | yes, when `UMAMI_SCRIPT_URL` and `UMAMI_WEBSITE_ID` are set |

## Configuration

GitHub secrets: `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`,
`BUTTONDOWN_API_KEY`.
GitHub variables: `UMAMI_SCRIPT_URL`, `UMAMI_WEBSITE_ID`.

`bin/stats` reads Umami from the environment and only works from the
tailnet (the API is not exposed publicly):

```sh
export UMAMI_API_URL=https://stats.delmai.re/api
export UMAMI_WEBSITE_ID=68ae8faf-60cd-40dd-8082-f5a404252596
export UMAMI_API_TOKEN=...  # read-only API key of the stats-reader user
```

The Buttondown username is `buttondown_username` in
`src/_data/site_metadata.yml`.
