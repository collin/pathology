def run_all_tests
  print `clear`
  puts "Tests run #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
  test_files = `find test |grep coffee | tr "\\n" " "`
  cleaned = test_files.split(" ").reject{|path| path["helper"]}.join(" ")
  puts "nodeunit #{cleaned}"
  puts `nodeunit #{cleaned}`
end

def run_tests(m)
  return if m.to_s["helper"]
  print `clear`
  puts "Tests run @ #{m} an #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
  puts `nodeunit #{m}`
end

run_all_tests
watch("(lib)(/.*)+.coffee") { |m|
  hit = m.to_s
  hit.gsub!(/^lib/, "test")
  run_tests(hit)
}
watch("(test)(/.*)+.coffee") { |m| run_tests(m) }

@interrupted = false

# Ctrl-C
Signal.trap "INT" do
  if @interrupted
    abort("\n")
  else
    puts "Interrupt a second time to quit"
    @interrupted = true
    Kernel.sleep 1.5

    run_all_tests
    @interrupted = false
  end
end
