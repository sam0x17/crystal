require "./spec/dsl"

# Crystal's built-in testing library. It provides a structure for writing executable examples
# of how your code should behave. A domain specific language allows you to write them in a way similar to natural language.
#
# The Crystal compiler has a `spec` command with tools to constrain which examples get run and tailor the output.
#
# A basic spec looks something like this:
#
# ```
# require "spec"
#
# describe Array do
#   describe "#size" do
#     it "correctly reports the number of elements in the Array" do
#       [1, 2, 3].size.should eq 3
#     end
#   end
#
#   describe "#empty?" do
#     it "is empty when no elements are in the array" do
#       ([] of Int32).empty?.should be_true
#     end
#
#     it "is not empty if there are elements in the array" do
#       [1].empty?.should be_false
#     end
#   end
#
#   # lots more specs
#
# end
# ```
#
# Test files are structured by use of the `describe` or `context` methods.
# Typically a top level `describe` defines the `outer` unit (such as a class)
# that is to be tested by the spec. Further `describe` calls can be nested within
# the outer unit to specify smaller units under test (such as individual methods).
# `describe` can also be used to set up a certain context - think empty `Array` versus
# `Array` with elements. The `context` method behaves just like the `describe` method
# and may be used instead, to emphasize context to the reader.
#
# Within a `describe` block, concrete test cases are defined with `it` . A
# descriptive string is supplied to `it` describing what the test case
# tests specifically.
#
# Specs then use the `should` method to verify that the expected value is
# returned. See the example above for details.
#
# By convention, specs live in the `spec` directory of a project. You can compile
# and run the specs of a project by running `crystal spec`.
#
# ```console
# # Run  all specs in files matching spec/**/*_spec.cr
# crystal spec
#
# # Run all specs in files matching spec/my/test/**/*_spec.cr
# crystal spec spec/my/test/
#
# # Run all specs in spec/my/test/file_spec.cr
# crystal spec spec/my/test/file_spec.cr
#
# # Run the spec or group defined in line 14 of spec/my/test/file_spec.cr
# crystal spec spec/my/test/file_spec.cr:14
# ```
module Spec
end

OptionParser.parse do |opts|
  opts.banner = "crystal spec runner"
  opts.on("-e ", "--example STRING", "run examples whose full nested names include STRING") do |pattern|
    Spec.pattern = pattern
  end
  opts.on("-l ", "--line LINE", "run examples whose line matches LINE") do |line|
    Spec.line = line.to_i
  end
  opts.on("-p", "--profile", "Print the 10 slowest specs") do
    Spec.slowest = 10
  end
  opts.on("--fail-fast", "abort the run on first failure") do
    Spec.fail_fast = true
  end
  opts.on("--location file:line", "run example at line 'line' in file 'file', multiple allowed") do |location|
    if location =~ /\A(.+?)\:(\d+)\Z/
      Spec.add_location $1, $2.to_i
    else
      STDERR.puts "location #{location} must be file:line"
      exit 1
    end
  end
  opts.on("--junit_output OUTPUT_DIR", "generate JUnit XML output") do |output_dir|
    junit_formatter = Spec::JUnitFormatter.file(output_dir)
    Spec.add_formatter(junit_formatter)
  end
  opts.on("--help", "show this help") do |pattern|
    puts opts
    exit
  end
  opts.on("-v", "--verbose", "verbose output") do
    Spec.override_default_formatter(Spec::VerboseFormatter.new)
  end
  opts.on("--tap", "Generate TAP output (Test Anything Protocol)") do
    Spec.override_default_formatter(Spec::TAPFormatter.new)
  end
  opts.on("--no-color", "Disable colored output") do
    Spec.use_colors = false
  end
  opts.unknown_args do |args|
  end
end

unless ARGV.empty?
  STDERR.puts "Error: unknown argument '#{ARGV.first}'"
  exit 1
end

if ENV["SPEC_VERBOSE"]? == "1"
  Spec.override_default_formatter(Spec::VerboseFormatter.new)
end

Spec.add_split_filter ENV["SPEC_SPLIT"]?

{% unless flag?(:win32) %}
  # TODO(windows): re-enable this once Signal is ported
  Signal::INT.trap { Spec.abort! }
{% end %}

Spec.run
