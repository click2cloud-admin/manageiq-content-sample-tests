module Cflab
  module StdLib
    module Core
      #*sigh*
    end
  end
end


shared_examples_for "Core StdLib" do
  puts "IM A SHARED EXAMPLE of [#{described_class}]"
  # dump_root = instance_double("dump_root")
  before { allow_any_instance_of(described_class).to receive(:dump_root) {
    # Stub implementation here
  }}
  before { allow_any_instance_of(described_class).to receive(:log) }
end