class Builders::CodeLanguageLabel < SiteBuilder
  BLOCK = /<div class="language-([\w+-]+) highlighter-rouge">/

  def build
    hook :resources, :post_render do |resource|
      resource.output = resource.output.gsub(BLOCK) do
        %(<div class="language-#{$1} highlighter-rouge" data-lang="#{$1}">)
      end
    end
  end
end
