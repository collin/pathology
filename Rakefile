abort "Use Ruby 1.9 to build AlphaSimprini" unless RUBY_VERSION["1.9"]

require 'rake-pipeline'
require 'colored'

def build
  Rake::Pipeline::Project.new("Assetfile")
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
  puts "Compiling CoffeeScript"
  `coffee -co lib/ src/`
  puts "Done"
end

desc "Build AlphaSimprini"
task :dist => [:coffeescript, :strip_whitespace] do
  puts "Building AlphaSimprini..."
  build.invoke
  puts "Done"
end

desc "Clean build artifacts from previous builds"
task :clean do
  puts "Cleaning build..."
  `rm -rf ./lib/*`
  build.clean
  puts "Done"
end

desc "Run tests with phantomjs"
task :test => :dist do |t, args|
  unless system("which phantomjs > /dev/null 2>&1")
    abort "PhantomJS is not installed. Download from http://phantomjs.org"
  end

  cmd = "phantomjs test/qunit/run-qunit.js \"file://localhost#{File.dirname(__FILE__)}/test/index.html\""

  # Run the tests
  puts "Running tests"
  puts cmd
  success = system(cmd)

  if success
    puts "Tests Passed".green
  else
    puts "Tests Failed".red
    exit(1)
  end
end
