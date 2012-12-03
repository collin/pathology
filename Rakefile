abort "Use Ruby 1.9 to build Pathology" unless RUBY_VERSION["1.9"]

require "./version"

require 'rake-pipeline'
require 'colored'
require 'github_uploader'
require "#{File.dirname(__FILE__)}/tasks/doc"

def build
  Rake::Pipeline::Project.new("Assetfile")
end

def err(*args)
  STDERR.puts(*args)
end

desc "Strip trailing whitespace for CoffeeScript files in packages"
task :strip_whitespace do
  Dir["{src,test}/**/*.coffee"].each do |name|
    body = File.read(name)
    File.open(name, "w") do |file|
      file.write body.gsub(/ +\n/, "\n")
    end
  end
end

desc "Compile CoffeeScript"
task :coffeescript => :clean do
  err "Compiling CoffeeScript"
  `coffee -co lib/ src/`
  err "Done"
end

desc "Build Pathology"
task :dist => [:coffeescript, :strip_whitespace] do
  err "Building Pathology..."
  build.invoke
  err "Done"
end

desc "Clean build artifacts from previous builds"
task :clean do
  err "Cleaning build..."
  `rm -rf ./lib/*`
  build.clean
  err "Done"
end

desc "upload versions"
task :upload => :test do
  load "./version.rb"
  uploader = GithubUploader.setup_uploader
  GithubUploader.upload_file uploader, "pathology-#{PATHOLOGY_VERSION}.js", "Pathology #{PATHOLOGY_VERSION}", "dist/pathology.js"
  GithubUploader.upload_file uploader, "pathology-#{PATHOLOGY_VERSION}-spade.js", "Pathology #{PATHOLOGY_VERSION} (minispade)", "dist/pathology-spade.js"
  GithubUploader.upload_file uploader, "pathology-#{PATHOLOGY_VERSION}.html", "Pathology #{PATHOLOGY_VERSION} (html_package)", "dist/pathology.html"

  GithubUploader.upload_file uploader, 'pathology-latest.js', "Current Pathology", "dist/pathology.js"
  GithubUploader.upload_file uploader, 'pathology-latest-spade.js', "Current Pathology (minispade)", "dist/pathology-spade.js"
end

def exec_test
  cmd = %|phantomjs ./test/qunit/run-qunit.js "file://localhost#{File.dirname(__FILE__)}/test/index.html"|

  # Run the tests
  err "Running tests"
  err cmd
  success = system(cmd)  
end

task :exec_test do
  exec_test
end

desc "Run tests with phantomjs"
task :test => [:phantomjs, :dist, :vendor] do |t, args|

  if exec_test
    err "Tests Passed".green
  else
    err "Tests Failed".red
    exit(1)
  end
end

desc "Install development dependencies with hip"
task :vendor => :dist do
  system "hip install --file=dist/pathology.html --out=./vendor --dev"
end

desc "tag/upload release"
task :release, [:version] => :test do |t, args|
  unless args[:version] and args[:version].match(/^[\d]+\.[\d]+\.[\d].*$/)
    raise "SPECIFY A VERSION curent version: #{PATHOLOGY_VERSION}"
  end
  File.open("./version.rb", "w") do |f| 
    f.write %|PATHOLOGY_VERSION = "#{args[:version]}"|
  end

  system "git add version.rb"
  system "git commit -m 'bumped version to #{args[:version]}'"
  system "git tag #{args[:version]}"
  system "git push origin master"
  system "git push origin #{args[:version]}"
  Rake::Task[:upload].invoke
end