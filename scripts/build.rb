#!/usr/bin/env ruby
# Generate the same static homepage for file:// previews and GitHub Pages.
require 'yaml'
require 'erb'
require 'cgi'
require 'pathname'
require 'digest'

class HomePage
  attr_reader :profile, :papers, :config, :students

  def initialize(root)
    @root = Pathname.new(root)
    @config = read_yaml('_config.yml')
    @profile = read_yaml('_data/profile.yml')
    @students = read_yaml('_data/students.yml')
    raise 'students.yml needs a title' unless students.is_a?(Hash) && students['title'].is_a?(String) && !students['title'].strip.empty?
    raise 'Student intro must be text' unless students['intro'].nil? || students['intro'].is_a?(String)
    { 'directions' => %w[title summary], 'proposals' => %w[title description url] }.each do |section, fields|
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
  end

  def read_yaml(path)
    YAML.safe_load(@root.join(path).read)
  end

  def h(value)
    CGI.escapeHTML(value.to_s)
  end

  def student_intro_text(value)
    email = h(profile['email'])
    h(value).gsub(/\*\*(.+?)\*\*/, '<strong>\1</strong>')
      .gsub(email) { "<a href=\"mailto:#{email}\">#{email}</a>" }
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
