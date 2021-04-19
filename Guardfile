require 'active_support/core_ext/string'
require 'appmap_depends'

def guard_debug?
  ENV['GUARD_DEBUG'] == 'true'
end

def rspec_debug?
  ENV['RSPEC_DEBUG'] == 'true'
end

def appmap_debug?
  ENV['APPMAP_DEBUG'] == 'true'
end

dirs = %w[api backend core frontend]

dirs.each do |dir|
  dirs.each do |subdir|
    guard :app_map_depends, debug: guard_debug? || appmap_debug?, appmap_dir: File.join(dir, 'tmp/appmap'), test_dir: dir, watch_dir: subdir do
      logger level: :debug if guard_debug? || appmap_debug?
      watch(%r{^#{subdir}/app/*})
      watch(%r{^#{subdir}/lib/*})
    end
  end

  guard :rspec, env: { 'APPMAP' => true }, chdir: dir, cmd: 'bundle exec rspec', all_on_start: false do
    logger level: :debug if guard_debug? || rspec_debug?
    watch(%r{^#{dir}/spec/.+_spec\.rb$})
  end  
end
