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

@gemspec_file = Dir['*.gemspec'].first

def gemspec
  @gemspec ||= Gem::Specification::load(@gemspec_file)
end

def version
  gemspec.version
end

def name
  gemspec.name
end

def platform
  gemspec.platform
end

def gem_file(platform)
  r = "#{name}-#{version}"
  r += "-#{platform}" if platform != 'ruby'
  r + '.gem'
end

def git_dirty?
  `git diff --shortstat 2>/dev/null`.chop != ''
end

def assert_git_clean
  raise 'Git must be clean before continuing' if git_dirty?
end

desc 'get version'
task :version do
  puts gemspec_object.version
end

def bump(idx)
  old_version = version.to_s
  v = old_version.split('.').map(&:to_i)
  v[idx] += 1
  new_version = v.map(&:to_s).join('.')
  assert_git_clean
  sh "sed -i '' -e 's/#{old_version}/#{new_version}/' '#{@gemspec_file}'"
  sh "git add #{@gemspec_file} && git commit -sS -am 'bump to #{new_version}'"
end

desc 'bump release'
task :bump do
  bump 2
end

desc 'bump minor'
task 'bump:minor' do
  bump 1
end

desc 'bump major'
task 'bump:major' do
  bump 0
end

desc 'release'
task :release => :test do
  assert_git_clean
  sh "git tag -s #{version} -m #{version} && git push --tags"
  sh "TMP_RUBIES=($RUBIES_ROOT/*); TMP_RUBIES=\"RUBIES=(${TMP_RUBIES[@]})\"; chruby-exec \"$TMP_RUBIES\" ruby-2.2.0 -- gem build #{@gemspec_file}"
  sh "TMP_RUBIES=($RUBIES_ROOT/*); TMP_RUBIES=\"RUBIES=(${TMP_RUBIES[@]})\"; chruby-exec \"$TMP_RUBIES\" jruby -- gem build #{@gemspec_file}"
  sh "gem push #{gem_file('ruby')}"
  sh "gem push #{gem_file('java')}"
end

task :default => :test
