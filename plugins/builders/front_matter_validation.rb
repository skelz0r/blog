require_relative "../../lib/post_checks"

class Builders::FrontMatterValidation < SiteBuilder
  def build
    hook :site, :post_read do |site|
      problems = site.collections.posts.resources.to_h do |post|
        [post.relative_path.to_s, PostChecks.front_matter_problems(post.path)]
      end.reject { |_, list| list.empty? }
      next if problems.empty?

      message = "Front matter check failed:\n#{PostChecks.report(problems)}"
      raise PostChecks::Failed, message if Bridgetown.env.production?

      Bridgetown.logger.warn "Front matter:", message
    end
  end
end
