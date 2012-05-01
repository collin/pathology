abort "Use Ruby 1.9 to build AlphaSimprini" unless RUBY_VERSION["1.9"]

require 'rake-pipeline'
require 'colored'

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

desc "Build AlphaSimprini"
task :dist => [:coffeescript, :strip_whitespace] do
  err "Building AlphaSimprini..."
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
task :test => [:phantomjs, :dist] do |t, args|
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
