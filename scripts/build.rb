#!/usr/bin/env ruby
# Generate the same static homepage for file:// previews and GitHub Pages.
require 'yaml'
require 'erb'
require 'cgi'
require 'pathname'
require 'digest'

class HomePage
  attr_reader :profile, :papers, :config, :students, :news

  # News `type` picks the icon; an item's own `icon` (any emoji) overrides it.
  NEWS_ICONS = {
    'accepted' => "\u{1F389}", # party popper
    'award' => "\u{1F3C6}",    # trophy
    'preprint' => "\u{1F4DD}", # memo
    'release' => "\u{1F680}",  # rocket
    'talk' => "\u{1F3A4}",     # microphone
    'news' => "\u{1F4E2}"      # loudspeaker
  }.freeze
  INLINE_LINK = /\[([^\]]+)\]\(([^)\s]+)\)/.freeze
  NEWS_VISIBLE = 5

  def initialize(root)
    @root = Pathname.new(root)
    @config = read_yaml('_config.yml')
    @profile = read_yaml('_data/profile.yml')
    @students = read_yaml('_data/students.yml')
    raise 'students.yml needs a title' unless students.is_a?(Hash) && students['title'].is_a?(String) && !students['title'].strip.empty?
    raise 'students.yml: intro has been split into looking_for and how_to_apply' if students.key?('intro')
    %w[looking_for how_to_apply email_subject].each do |field|
      raise "Student #{field} must be text" unless students[field].nil? || students[field].is_a?(String)
    end
    text = ->(value) { value.is_a?(String) && !value.strip.empty? }
    students.fetch('directions', []).each do |direction|
      raise 'Student direction needs a title' unless direction.is_a?(Hash) && text.call(direction['title'])
      raise "Student direction summary must be text: #{direction['title']}" unless direction['summary'].nil? || text.call(direction['summary'])
      aspects = direction.fetch('aspects', [])
      raise "Student direction aspects must be a list of text: #{direction['title']}" unless aspects.is_a?(Array) && aspects.all?(&text)
      raise "Student direction needs a summary or aspects: #{direction['title']}" if direction['summary'].nil? && aspects.empty?
    end
    { 'directions' => %w[title], 'proposals' => %w[title description url] }.each do |section, fields|
      entries = students.fetch(section, [])
      raise "Student #{section} must be a list" unless entries.is_a?(Array)
      entries.each do |entry|
        raise "Student #{section} entry needs #{fields.join(', ')}" unless entry.is_a?(Hash) && fields.all? { |field| entry[field].is_a?(String) && !entry[field].strip.empty? }
        if section == 'proposals'
          unless entry['url'].match?(%r{\Ahttps?://}i)
            raise 'Local proposals must be in assets/' unless entry['url'].start_with?('assets/')
            local_asset(entry['url'])
          end
        end
      end
    end
    records = read_yaml('_data/publications.yml')
    raise 'publications.yml must contain a list of papers' unless records.is_a?(Array)
    ids = []
    records.each do |paper|
      %w[id title authors year venue].each do |field|
        raise "Missing #{field} in publication #{paper['id'].inspect}" if paper[field].nil? || paper[field].to_s.empty?
      end
      raise "Duplicate publication id: #{paper['id']}" if ids.include?(paper['id'])
      raise "Invalid publication id: #{paper['id']}" unless paper['id'].match?(/\A[a-z0-9][a-z0-9-]*\z/)
      raise "Invalid year: #{paper['id']}" unless paper['year'].is_a?(Integer)
      raise "Invalid authors: #{paper['id']}" unless paper['authors'].is_a?(Array) && !paper['authors'].empty? && paper['authors'].all? { |author| author.is_a?(String) && !author.empty? }
      if paper.key?('selected') && ![true, false].include?(paper['selected'])
        raise "selected must be true or false: #{paper['id']}"
      end
      if paper.key?('paper') && !(paper['paper'].is_a?(String) && paper['paper'].match?(%r{\Ahttps?://}i))
        raise "paper must be an HTTP(S) URL when provided: #{paper['id']}"
      end
      if paper.key?('classification') && !(paper['classification'].is_a?(String) && !paper['classification'].strip.empty?)
        raise "classification must be text such as CCF-A: #{paper['id']}"
      end
      if paper['video'] && !(paper['video'].is_a?(String) && paper['video'].match?(%r{\Ahttps?://}i))
        raise "video must be an HTTP(S) URL: #{paper['id']}"
      end
      if paper['award_image']
        raise "award_image requires an award label: #{paper['id']}" if paper['award'].to_s.strip.empty?
        local_asset(paper['award_image'])
      end
      if paper['highlight']
        highlight = paper['highlight']
        raise "highlight needs name and summary: #{paper['id']}" unless highlight.is_a?(Hash) && %w[name summary].all? { |key| highlight[key].is_a?(String) && !highlight[key].strip.empty? }
        if highlight['result'] && %w[result_label conditions].any? { |key| highlight[key].to_s.strip.empty? }
          raise "A research result needs result_label and conditions: #{paper['id']}"
        end
        if highlight['image']
          visual = highlight['image']
          raise "highlight image needs path and alt: #{paper['id']}" unless visual.is_a?(Hash) && %w[path alt].all? { |key| visual[key].is_a?(String) && !visual[key].strip.empty? }
          local_asset(visual['path'])
          if visual['source'] && !visual['source'].to_s.match?(%r{\Ahttps?://}i)
            raise "highlight image source must be an HTTP(S) URL: #{paper['id']}"
          end
        end
      end
      ids << paper['id']
    end
    @papers = records.each_with_index.sort_by { |paper, index| [-paper['year'], index] }.map(&:first)
    @news = load_news
  end

  # Newest month first; items within the same month keep their order in news.yml.
  def load_news
    items = read_yaml('_data/news.yml') || []
    raise 'news.yml must contain a list of news items' unless items.is_a?(Array)
    anchors = %w[about hiring news research students publications contact] +
      papers.map { |paper| "paper-#{paper['id']}" } +
      papers.select { |paper| paper['highlight'] }.map { |paper| "highlight-#{paper['id']}" }
    items.each do |item|
      unless item.is_a?(Hash) && item['date'].is_a?(String) && item['text'].is_a?(String) && !item['text'].strip.empty?
        raise "Each news item needs a quoted date and text: #{item.inspect}"
      end
      date = item['date'].match(/\A(\d{4})-(\d{2})(?:-(\d{2}))?\z/)
      unless date && (1..12).cover?(date[2].to_i) && (date[3].nil? || (1..31).cover?(date[3].to_i))
        raise "News date must be \"YYYY-MM\" or \"YYYY-MM-DD\": #{item['date']}"
      end
      if item.key?('type') && !NEWS_ICONS.key?(item['type'])
        raise "News type must be one of #{NEWS_ICONS.keys.join(', ')}: #{item['type'].inspect}"
      end
      if item.key?('icon') && !(item['icon'].is_a?(String) && (1..8).cover?(item['icon'].strip.length))
        raise "News icon must be a single emoji: #{item['icon'].inspect}"
      end
      item['text'].scan(INLINE_LINK) do |_label, url|
        if url.start_with?('#')
          raise "News link points to a missing section or paper: #{url}" unless anchors.include?(url[1..-1])
        elsif !url.match?(%r{\Ahttps?://}i)
          raise "News links must start with https://, assets/ or #: #{url}" unless url.start_with?('assets/')
          local_asset(url)
        end
      end
    end
    items.each_with_index.sort_by { |item, index| [-item['date'][0, 7].delete('-').to_i, index] }.map(&:first)
  end

  def read_yaml(path)
    YAML.safe_load(@root.join(path).read)
  rescue Psych::DisallowedClass => error
    raise "#{path}: #{error.message}. Put dates in quotes, e.g. date: \"2026-09\""
  end

  # News text: **bold** and [label](url); links are validated in load_news.
  def inline_text(value)
    h(value).gsub(/\*\*(.+?)\*\*/, '<strong>\1</strong>')
      .gsub(INLINE_LINK) { "<a href=\"#{Regexp.last_match(2)}\">#{Regexp.last_match(1)}</a>" }
  end

  def news_month(item)
    item['date'][0, 7].tr('-', '.')
  end

  def news_icon(item)
    item['icon'] ? item['icon'].strip : NEWS_ICONS.fetch(item['type'] || 'news')
  end

  def h(value)
    CGI.escapeHTML(value.to_s)
  end

  # Email links in the student section pre-fill the suggested subject line.
  def student_mailto
    subject = students['email_subject'].to_s.strip
    "mailto:#{profile['email']}" + (subject.empty? ? '' : "?subject=#{ERB::Util.url_encode(subject)}")
  end

  def student_text(value)
    email = h(profile['email'])
    h(value).gsub(/\*\*(.+?)\*\*/, '<strong>\1</strong>')
      .gsub(email) { "<a href=\"#{h(student_mailto)}\">#{email}</a>" }
  end

  def student_paragraphs(value)
    value.to_s.strip.split(/\n\s*\n/).map { |paragraph| student_text(paragraph) }
  end

  def classification_badge(paper)
    value = paper['classification'].to_s.strip
    return '' if value.empty?
    rank = value[/\ACCF-([ABC])\z/, 1]
    title = rank ? %( title="China Computer Federation (CCF) recommended venue, class #{rank}") : ''
    %(<span class="badge badge-rank"#{title}>#{h(value)}</span>)
  end

  def local_asset(path)
    relative = path.to_s.sub(%r{\A/+}, '')
    asset = @root.join(relative).cleanpath
    raise "Missing local asset: #{relative}" unless asset.to_s.start_with?(@root.to_s + '/') && asset.file?
    relative
  end

  def absolute_url(path = '')
    base = [config.fetch('url').sub(%r{/+\z}, ''), config.fetch('baseurl', '').sub(%r{\A/+}, '').sub(%r{/+\z}, '')].reject(&:empty?).join('/')
    base + '/' + path.to_s.sub(%r{\A/+}, '')
  end

  def versioned_asset(path)
    relative = local_asset(path)
    version = Digest::SHA256.file(@root.join(relative)).hexdigest[0, 12]
    "#{relative}?v=#{version}"
  end

  def render(name, **locals)
    context = binding
    locals.each { |key, value| context.local_variable_set(key, value) }
    ERB.new(@root.join('_templates', name + '.html.erb').read, trim_mode: '-').result(context)
  end
end

if __FILE__ == $PROGRAM_NAME
  begin
    raise 'Usage: ruby scripts/build.rb [--check]' unless ARGV.empty? || ARGV == ['--check']
    root = File.expand_path('..', __dir__)
    page = HomePage.new(root)
    output = page.render('home')
    destination = File.join(root, 'index.html')
    if ARGV == ['--check']
      raise 'index.html is out of date. Run: ruby scripts/build.rb' unless File.file?(destination) && File.read(destination) == output
      puts 'index.html is up to date.'
    else
      File.write(destination, output)
      puts "已更新 index.html（#{page.papers.size} 篇论文）。可直接用浏览器打开。"
    end
  rescue StandardError => error
    warn "主页生成失败：#{error.message}"
    exit 1
  end
end
