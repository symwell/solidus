require 'active_support/core_ext/string'

def guard_debug?
  ENV['GUARD_DEBUG'] == 'true'
end

def rspec_debug?
  ENV['RSPEC_DEBUG'] == 'true'
end

def appmap_debug?
  ENV['APPMAP_DEBUG'] == 'true'
end

guard :rspec, cmd: 'bundle exec rspec', all_on_start: false do
  logger level: :debug if guard_debug? || rspec_debug?
  watch(%r{^spec/.+_spec\.rb$})
end
