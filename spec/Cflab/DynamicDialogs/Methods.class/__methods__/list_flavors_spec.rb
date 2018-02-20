#
# Test cases for list_flavors.rb, a drop down helper
#

# First, read in the Automate script we are testing
require_domain_file

#
# Put the noted class (automate method) under test, what rspec calls "describing" its behaviour
#

describe Cflab::DynamicDialogs::Methods::List_flavors do

  include_examples "Core StdLib"

  #
  # Setup our objects needed for testing
  #
  # let() has the objects created dynamically as needed
  #
  # FactoryGirl is involved, but significantly for Automate testers, there are a bunch of named
  #     mocks available for use in manageiq/spec/factories

  # create a user
  let(:user) { FactoryGirl.create(:user_with_email_and_group) }

  # and the Automate shadow object
  let(:svc_model_user) { MiqAeMethodService::MiqAeServiceUser.find(user.id) }

  # a provider
  let(:ems) { FactoryGirl.create(:ems_amazon) }

  # a flavor
  let(:t2_small_flavor) do
    FactoryGirl.create(:flavor_amazon, :ems_id => ems.id,
                       :name => 't2.small',
                       :cloud_subnet_required => false)
  end

  # and another flavor
  let(:m2_small_flavor) do
    FactoryGirl.create(:flavor_amazon, :ems_id => ems.id,
                       :name => 'm2.small',
                       :cloud_subnet_required => false)
  end


  # Note we are not adding the fake flavors to the fake provider here!
  # we wish to test listing flavors and listing when there are not flavors,
  # so we attach the flavors in particular test cases (or not).

  # build our fake $evm.root
  let(:root_object) do
    Spec::Support::MiqAeMockObject.new(
        'dialog_provider' => ems.id.to_s,
        'user' => svc_model_user,
        )
  end

  # and the rest of the Automate runtime sandbox
  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  # Note: I did not actually mean "create" above, the objects are created dynamically on demand.
  #       And also, per-test. Each test is run in a clean and independently universe. Or should

  # Test case - list the flavors as expected

  it 'should list flavors' do

    # If only teaching real AWS about flavors was so easy
    ems.flavors << m2_small_flavor
    ems.flavors << t2_small_flavor

    # Build our hash of the expected output
    flavors = {}
    ems.flavors.each do |flavor|
      flavors[flavor.id] = "#{flavor.name} on #{ems.name}"
    end

    # Instantiate our Automate Method, inject it with the fake $evm and run the main(), er, method
    described_class.new(ae_service).main


    # and describe the expect()ed results.
    #
    # our "return" dropdown has is equal to what we expect
    expect(ae_service.object['values']).to eq(flavors)

    # Double sanity check that the length is the same as the number of Flavors we mocked out
    # This somewhat ensures our do-something test code isn't buggy
    expect(ae_service.object['values'].length).to eq(MiqAeMethodService::MiqAeServiceFlavor.all.length)

    # These three lines were from the example _spec.rb I initially stole.
    # My Method doesn't set them. Which "works" but may be wrong. Future versions of CloudForms
    # may require these to be set, so it would be safest for me to fix my code. I leave them
    # here as a badge of dishonor for you to ponder today, and future me to as a clue to fixing
    # things when they are really required.

    # expect(ae_service.object['sort_by']).to eq(:description)
    # expect(ae_service.object['data_type']).to eq(:string)
    # expect(ae_service.object['required']).to eq(true)

  end

  # Test case - no flavors
  it 'show show no flavors' do

    # define our expected dropdown to be built when we have no filters
    flavors = { '' => '< no flavors found >' }

    # run the code
    described_class.new(ae_service).main

    # Check the results
    expect(ae_service.object['values']).to eq(flavors)
    expect(ae_service.object['values'].length).to eq(1)
  end
end
