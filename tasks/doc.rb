SOURCES = File.join File.dirname(__FILE__), "..", "src"

desc "Create json document object"
task :jsondoc => [:phantomjs, :dist] do
  cmd = %|phantomjs #{SOURCES}/gather-docs.coffee "file://localhost#{SOURCES}/gather-docs.html"|

  # err "Running tests"
  # err cmd
  # success = `#{cmd}`

  # if success
  #   err "Built JSON".green
  #   FileUtils.safe_unlink "dist/docs.json"
  #   File.open("dist/docs.json", "w") {|f| f.write success }
  # else
  #   err "Failed".red
  #   exit(1)
  # end

end

task :phantomjs do
  unless system("which phantomjs > /dev/null 2>&1")
    abort "PhantomJS is not installed. Download from http://phantomjs.org"
  end
end
