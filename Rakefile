# frozen_string_literal: true

require 'bundler'

task default: :spec

def print_title(gem_name = '')
  title = ["Solidus", gem_name].join(' ').strip
  puts "\n#{'-' * title.size}\n#{title}\n#{'-' * title.size}"
end

def subproject_task(project, task, title: project, task_name: nil)
  task_name ||= "#{task}:#{project}"
  task task_name do
    print_title(title)
    Dir.chdir("#{File.dirname(__FILE__)}/#{project}") do
      sh "rake #{task}"
    end
  end
end

namespace :rspec do
  def rake_debug
    ENV['DEBUG'] == 'true' || ENV['RAKE_DEBUG'] == 'true'
  end

  def appmap_debug
    ENV['DEBUG'] == 'true' || ENV['APPMAP_DEBUG'] == 'true'
  end

  Example = Struct.new(:location, :status) do
    def path
      location.split('[')[0]
    end

    def failed?
      status == 'failed'
    end
  end

  desc 'Run incremental RSpecs'
  task :incremental, %w[project base] do |_, args|
    project = args[:project]
    Dir.chdir("#{File.dirname(__FILE__)}/#{project}") do
      main = args[:base] || 'origin/main'
      system %(env NODE_OPTIONS="--trace-warnings" appmap-js #{appmap_debug ? '--verbose' : ''} fingerprint)

      updated_files = []
      begin
        src_files = nil
        absolute_src_files = nil
        Dir.chdir '..' do
          cmd = %(git diff --name-only #{main})
          $stderr.puts cmd if rake_debug
          src_files = `#{cmd}`.split("\n")
          absolute_src_files = src_files.map { |file| File.absolute_path(file) }
          src_files = src_files.map{|file| (file.strip.split('/')[1..-1] || []).join('/')}.select{|line| !line.empty?}
          $stderr.puts "Modified source files: [#{src_files.join(' ')}]"
        end
      end

      src_files += absolute_src_files
      cmd = %(env NODE_OPTIONS="--trace-warnings" appmap-js depends --field source_location #{src_files.join(' ')})
      $stderr.puts cmd if rake_debug
      depends = `#{cmd}`.split("\n")
      $stderr.puts depends if rake_debug

      $stderr.puts "Running due to dependency check: #{depends.join(' ')}" unless depends.empty?
      updated_files += depends

      begin
        cmd = %(git diff --name-only #{main} spec)
        $stderr.puts cmd if rake_debug
        depends = `#{cmd}`.split("\n")
        $stderr.puts depends if rake_debug
        $stderr.puts "Running due to direct modification: #{depends.join(', ')}" unless depends.empty?
        updated_files += depends
      end
      begin
        examples = begin
          File.read('spec/examples.txt').split("\n")[1..-1]
        rescue Errno::ENOENT
          []
        end
        failed_examples = examples.map do |line|
            fields = line.split('|').map(&:strip)
            example = Example.new(*fields[0..1])
          end.select(&:failed?)
        $stderr.puts "Failed examples: #{failed_examples.map(&:location).join(' ')}" if rake_debug
        updated_files += failed_examples.map(&:path)
      end
      updated_files.uniq!
      if updated_files.empty?
        $stderr.puts 'RSpec testing is up to date'
      else
        Bundler.with_unbundled_env do
          cmd = %(env APPMAP=true bundle exec rspec --color #{updated_files.join(' ')})
          $stderr.puts cmd if rake_debug
          system cmd
        end
      end
    end
  end
end

%w[spec db:drop db:create db:migrate db:reset].each do |task|
  %w(api backend core frontend sample).each do |project|
    desc "Run specs for #{project}" if task == 'spec'
    subproject_task(project, task)
  end

  desc "Run rake #{task} for each Solidus engine"
  task task => %w(api backend core frontend sample).map { |p| "#{task}:#{p}" }
end

desc "Run backend JS specs"
subproject_task("backend", "spec:js", title: "backend JS", task_name: "spec:backend:js")

# Add backend JS specs to `rake spec` dependencies
task spec: 'spec:backend:js'

task test: :spec
task test_app: 'db:reset'

desc "clean the whole repository by removing all the generated files"
task :clean do
  rm_f  "Gemfile.lock"
  rm_rf "sandbox"
  rm_rf "pkg"

  %w(api backend core frontend sample).each do |gem_name|
    print_title(gem_name)
    rm_f  "#{gem_name}/Gemfile.lock"
    rm_rf "#{gem_name}/pkg"
    rm_rf "#{gem_name}/spec/dummy"
  end
end

namespace :gem do
  def version
    require_relative 'core/lib/spree/core/version'
    Spree.solidus_version
  end

  def for_each_gem
    %w(core api backend frontend sample).each do |gem_name|
      print_title(gem_name)
      yield "pkg/solidus_#{gem_name}-#{version}.gem"
    end
    print_title
    yield "pkg/solidus-#{version}.gem"
  end

  desc "Build all solidus gems"
  task :build do
    pkgdir = File.expand_path('pkg', __dir__)
    FileUtils.mkdir_p pkgdir

    %w(core api backend frontend sample).each do |gem_name|
      Dir.chdir(gem_name) do
        sh "gem build solidus_#{gem_name}.gemspec"
        mv "solidus_#{gem_name}-#{version}.gem", pkgdir
      end
    end

    print_title
    sh "gem build solidus.gemspec"
    mv "solidus-#{version}.gem", pkgdir
  end

  desc "Install all solidus gems"
  task install: :build do
    for_each_gem do |gem_path|
      Bundler.with_clean_env do
        sh "gem install #{gem_path}"
      end
    end
  end

  desc "Release all gems to rubygems"
  task release: :build do
    sh "git tag -a -m \"Version #{version}\" v#{version}"

    for_each_gem do |gem_path|
      sh "gem push '#{gem_path}'"
    end
  end
end

desc "Creates a sandbox application for simulating the Solidus code in a deployed Rails app"
task :sandbox do
  warn "Using `rake sandbox` is deprecated, please use bin/sandbox directly instead."
  sh("bin/sandbox")
end
