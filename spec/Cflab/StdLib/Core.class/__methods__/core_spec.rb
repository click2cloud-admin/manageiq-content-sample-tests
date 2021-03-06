#
# Test cases for core.rb, our "standard library"
#

# First, read in the Automate script we are testing
require_domain_file

# Testing black magic here.
# Since core.rb doesn't define a class, let alone initialize an object, per "regular" Automate "methods",
# and the (ruby) methods are "class" (static) methods, but _do_ depend on Instance variables,
# we need to a concrete class to instantiate, with the most bare of details.
#
# Note also, because we are monkey patching in the class hierchy later (dummy_class.extend()), while
# super(handle) would be the right thing, it isn't possible here.
#

class DummyClass
  def initialize(handle = $evm)
    @handle = handle
  end
end

describe Cflab::StdLib::Core do

  # Note: Don't do this. We actually want to test Core StdLib, not the super dummy version of it
  # include_examples "Core StdLib"

  before(:each) do
    @dummy_class = DummyClass.new(ae_service)
    @dummy_class.extend(Cflab::StdLib::Core)
  end


  # create a user
  let(:user) {FactoryGirl.create(:user_with_email_and_group)}

  # and the Automate shadow object
  let(:svc_model_user) {MiqAeMethodService::MiqAeServiceUser.find(user.id)}

  # a provider
  let(:ems) {FactoryGirl.create(:ext_management_system)}

  # build our fake $evm.root
  let(:root_object) do
    Spec::Support::MiqAeMockObject.new(
        'dialog_provider' => ems.id.to_s,
        'user' => svc_model_user,
        )
  end

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end

  end

  it 'should log' do
    expect(ae_service).to receive(:log).exactly(1).times
    @dummy_class.log(:info, "Something")
  end

  it 'dump_root should produce the right number of lines' do
    log_header_footer_count = 3
    expect(ae_service).to receive(:log).exactly(root_object.attributes.size + log_header_footer_count).times
    @dummy_class.dump_root()
  end

end
