require "date"
require "yaml"

module PostChecks
  DESCRIPTION_LENGTH = 150..160
  FRONT_MATTER = /\A---\s*\n(.*?)\n---\s*$/m

  class Failed < StandardError; end

  module_function

  def front_matter(path)
    match = File.read(path).match(FRONT_MATTER)
    return {} unless match

    YAML.safe_load(match[1], permitted_classes: [Date, Time]) || {}
  end

  def front_matter_problems(path)
    data = front_matter(path)
    problems = []
    problems << "title is missing" if blank?(data["title"])
    problems.concat(description_problems(data["description"]))
    problems << "date is missing" if blank?(data["date"])
    problems << "tags must be a non-empty list" unless tags?(data["tags"])
    problems
  end

  def description_problems(description)
    return ["description is missing"] if blank?(description)

    length = description.to_s.strip.length
    return [] if DESCRIPTION_LENGTH.cover?(length)

    ["description is #{length} characters, expected #{DESCRIPTION_LENGTH.min}-#{DESCRIPTION_LENGTH.max}"]
  end

  def tags?(tags)
    [*tags] == tags && tags.any? && tags.none? { |tag| blank?(tag) }
  end

  def blank?(value)
    value.to_s.strip.empty?
  end

  def report(problems_by_file)
    problems_by_file.map do |file, problems|
      ["#{file}:", *problems.map { |problem| "  - #{problem}" }].join("\n")
    end.join("\n")
  end
end
