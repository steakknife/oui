def root
  @root ||= File.expand_path(File.join('..'), __FILE__)
end

def bundle_sh(*args)
  if File.directory?(File.join(root, 'vendor', 'bundle'))
    if args.length == 1
      args = "bundle exec #{args[0]}"
    else
      args = args.unshift(%w[bundle exec])
    end
  end
  sh(*args)
end

desc 'Run test cases'
task :test do
  bundle_sh "ruby -Ilib:test #{File.join(root, 'test', 'test_oui.rb')}"
end

task :default => :test
