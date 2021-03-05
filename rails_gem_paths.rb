#!/usr/bin/env ruby

gems = Bundler.definition.resolve.select {|n| n.name =~ /^active/ || n.name =~ /^action/ }.sort { |a,b| a.name <=> b.name }
$stderr.puts gems.map { |gem| "# - gem: #{gem.name}" }.join("\n")
paths = gems.map { |gem| Gem.loaded_specs[gem.name].full_gem_path }
puts paths.join(' ')
