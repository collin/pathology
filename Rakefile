abort "Use Ruby 1.9 to build Pathology" unless RUBY_VERSION["1.9"]

require "./version"

require 'rake-pipeline'
require 'colored'
require 'github_uploader'

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
  uploader = GithubUploader.setup_uploader
  GithubUploader.upload_file uploader, "pathology-#{PATHOLOGY_VERSION}.js", "Pathology #{PATHOLOGY_VERSION}", "dist/pathology.js"
  GithubUploader.upload_file uploader, "pathology-#{PATHOLOGY_VERSION}-spade.js", "Pathology #{PATHOLOGY_VERSION} (minispade)", "dist/pathology-spade.js"
  GithubUploader.upload_file uploader, "pathology-#{PATHOLOGY_VERSION}.html", "Pathology #{PATHOLOGY_VERSION} (html_package)", "dist/pathology.html"

  GithubUploader.upload_file uploader, 'pathology-latest.js', "Current Pathology", "dist/pathology.js"
  GithubUploader.upload_file uploader, 'pathology-latest-spade.js', "Current Pathology (minispade)", "dist/pathology-spade.js"
end

desc "Create json document object"
task :jsondoc => [:phantomjs, :dist] do
  cmd = "phantomjs src/gather-docs.coffee \"file://localhost#{File.dirname(__FILE__)}/src/gather-docs.html\""  

  err "Running tests"
  err cmd
  success = `#{cmd}`

  if success
    err "Built JSON".green
    FileUtils.safe_unlink "dist/docs.json"
    File.open("dist/docs.json", "w") {|f| f.write success }
  else
    err "Failed".red
    exit(1)
  end

end

task :phantomjs do
  unless system("which phantomjs > /dev/null 2>&1")
    abort "PhantomJS is not installed. Download from http://phantomjs.org"
  end
end

desc "Run tests with phantomjs"
task :test => [:phantomjs, :dist, :vendor] do |t, args|
  cmd = "phantomjs test/qunit/run-qunit.js \"file://localhost#{File.dirname(__FILE__)}/test/index.html\""

  # Run the tests
  err "Running tests"
  err cmd
  success = system(cmd)

  if success
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
  unless args[:version] and args[:version].match[/^[\d]{3}$/]
    raise "SPECIFY A VERSION curent version: #{PATHOLOGY_VERSION}"
  end
  File.open("./version.rb", "w") do |f| 
    f.write %|PATHOLOGY_VERSION = "#{args[:version]}"|
  end

  system "git add version.rb"
  system "git commit -m 'bumped version to #{args[:version]}'"
  system "git tag #{args[:version]}"
  system "git push origin master"
  Rake::Task[:upload].invoke
end