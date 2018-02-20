# Introduction
This document is an introduction into the process of unit testing CloudForms Automation methods.

Inspired by Christian Jung teaser introduction to some CloudForms Automation best practices at [http://www.jung-christian.de/post/2017/10/automate-best-practice/](http://www.jung-christian.de/post/2017/10/automate-best-practice/), this serves to expand on that, and provided details of that for administrator/developer of CloudForms who perhaps isn’t familiar with the tools and concepts discussed.

**Note** This document is written against PR ManageIQ/manageiq-content/pull/250 ,

# Goals

Our ultimate goal is to have an environment for unit testing our Automate methods.

Initially, it is to setup an environment to do so, and to actually test a simple Automate method.

Later, if it can happen, I'll attempt to mock out a third party API service.

## Setting Up a Development Environment

This was, frankly, a huge pain. I was ultimately unable to make it happen on my corporate build, so spun up a Fedora 27 VM and started fresh from there.

### End State

So you know where we’re heading, we end up with the following top level directory structure, with noted manual symlinks at lower levels. Note that case matter

```
Projects/
Projects/manageiq-content (from github)
Projects/manageiq (from github)
Projects/CFLAB/datastore (Automate export from CloudForms)

Projects/manageiq-content/content/automate/Cflab -> Projects/CFLAB/datastore/cflab
Projects/manageiq-content/spec/content/automate/Cflab -> Projects/CFLAB/specs/Cflab
Projects/manageiq-content/spec/manageiq -> Projects/manageiq
```

The official ManageIQ guide may be due for detailed fact checking, but is as good as I could rewrite. [http://manageiq.org/docs/guides/developer_setup](http://manageiq.org/docs/guides/developer_setup) . If you can get a ManageIQ application up and running, you’ve got what you need as far as the base application and dependencies.

Additionally, clone and install the ```manageiq-content``` repository. Use the symlink option to link to the ```manageiq``` repository.

## Crash Course on Cloning, Linking, and Syncing Repositories

Following the above and official instructions, your local working repositories will be the master branch from git. That is, the bleeding edge version in active development, and for end users unquestionably, not what you want for a stable test environment.

Ideally, we would be running our tests of Automate against the exact version as is on the appliances we care about. In practice, this may be impossible to achieve, and the latest version of the matching branch of the relevant repositories ManageIQ to CloudForms is close enough. For CloudForms 4.6, we want the gaprindashvili branches of ```manageiq``` and ```manageiq-content```.

Since it is unlikely this exercise will have you attempting to push code to any of the ManageIQ repositories, the following git magic may be overkill. However, it isn’t a lot overhead, and you may customize your test environment and want to keep that either private, or share it, and doing the right git thing helps in either case. 

* On GitHub, fork each of the respective repositories

* Clone your new personal (and currently identical) repository:
 
  ```git clone git@github.com:<yourname>/<repo>.git```

* Connect your local copy to the upstream repository, and sync:

  ```git remote add upstream git@github.com:<yourname>/<repo>.git```
  
  ```git fetch upstream```

* Checkout the named branch for the relevant version you want. With “tracking”, so you could push local changes to your github repository:

  ```git checkout -t origin/gaprindashvili```

* Every once in a while, pull and merge any changes from the upstream, official repositories

  ```git merge upstream/gaprindashvili```

* And push them to your github as well

   ```git push```

* If you have made any local changes, there will be stuff to do between merge/push

There are two repositories we care about, manageiq and manageiq-content; do the above git magic for both.

**Tip**: [https://github.com/magicmonty/bash-git-prompt](https://github.com/magicmonty/bash-git-prompt) provides a very nice Bash prompt for helping to keep track of git shenanigans.

## Sanity Check: Run The Test Suite

From the top of manageiq-content, run bundle exec rake, and when done, point a browser at manageiq-content/coverage/index.html.

If everything is working, you should see a code coverage report from the ManageIQ automate domain.

**Note**: This reports raw coverage numbers are biased twice: the _spec.rb files are included, which get at or near 100% coverage, and only automate code that has any tests at all are counted.

If you have gotten this far, you have proven out your environment by testing existing code.

# On to testing

## Some Theory

This document does not serve as full guide to to Unit Testing, Test Driven Development, or how to write good tests. Far superior references exist and are outside the scope of this effort, however, a quick recap is necessary.

First consider the difference of _testing_ code and _testable_ code. Theoretical concerns of the halting problem aside, in practice, automated testing of code realistically require code to be written to be testable, to be testable by a particular test framework toolset, and to be testable within some project specific conventions and build environment. Further the ManageIQ Automate engine and sandbox requires special consideration to workaround.

ManageIQ Automate code, by its design and purpose, manipulates a large number of components outside the control of the Automate developer, i.e. the rest of ManageIQ outside the sandbox (and the external providers it connects to!), and any remote APIs that Automate may directly interact with. Testing the method of the second state of a State machine necessitates running the first state (and, if it works, usually additional states), or cutting and pasting of code into a Rails console, or other ad hock hacks. This takes time and is cumbersome at best. It manipulates the real world environment, and even if a lab, minimally requires the tester to reset the outside systems to a good state, likely disrupts other people, and can cost real money.

In _Unit_ testing we test individual Units, that is, individual Automate Methods. We provide a simulated environment, providing test objects, known as Test Doubles, and validating our code runs as expected. Because they are simulated, they run quickly and do not touch the real world. Being simulated, resetting them is as simple as running the test again. We can test not only properly working systems, but realistic but nearly impossible failure conditions, from near-full disk to REST call timeouts. We can do so without hacking the network, or intentionally breaking the lab, and we can do so repeatedly as we make iteratively changes to our code.

It is worth highlighting our goal here is _unit_ testing code. We are not simulating entire workflows. We are not simulating Automate State Machines.

During the development lifecycle, as a new Automate Method is developed, we can only realistically expect to test for conditions we expect to happen - we only know what we know. As code enters manual full testing, and use with real users and live systems, more and more unimaginable user inputs and API responses will be encountered. With simulated objects, we can simulate "impossible" results from integration points, and handle them rigorously at our leisure, rather then relying on luck to fix them in the moment. As the _unit_ is improved to handle what yesterday we knew to be impossible, the _unit test_ is improved to simulate the impossible.

The ultimate output of Unit Testing is a report showing test results (pass/fail), and code coverage reports. Test results obviously show if the "Unit Under Test" (UUT) operates as the test desires. The code coverage reports display what code has been run (and what has not). How _well_ it has been tested is a different question, but an Automate method where a test exercises 100% of the lines & branches at least is guaranteed not to have syntax errors. Unit testing will also not help you convince a project manager that it meets a requirement, though a rigorous testing framework does provide evidence that _you_ did not break anything when you touched it.

_Test Driven Development_ is the idea of writing test cases before and with the run time code. ```rspec```, the Ruby testing framework takes this concept further, describing it as "Behaviour Driven Development": describing a desired behaviour of a unit (Automate method) through a unit test.

### Test Doubles

.....

## Back to reality

For testing of any piece of existing Automate code, it will requires at least mechanical and trivial changes into a testable form. A complicated automate method may well require extensive refactoring to get to 100% line coverage, let alone 100% functional coverage. Don’t expect to _test_ your code without a little bit of effort to make it _testable_ code. 

Most of what Automate code does is call to external resources, be it the core code accessible from evm, the systems indirectly accessible through evm, or external APIs.

Net new automate methods, built with a test driven development methodology will have these conventions in place implicity. It may seem odd to write more functional code (and ugly boilerplate code at that), and at least as much test code, but when the practical CloudForms alternative is often waiting 15 minutes for a provision to fail, a rigorous test suite up front is less time overall.

Broadly, testing an automate method from the wild will consists of doing the following:

* Wrapping the core code in module/class decorations

* Wrapping the main code in a `main()` function definition

* Adding an `initialize()` method to allow injecting a mock `$evm` into `@handle`

* Tweaking any existing code to use `@handle` _viz_ `$evm`

* Writing spec files (the tests themselves) to test the code

  * Wiring up and configuring existing Test Doubles
  * Writing and configuring new test doubles, if required

* Optionally, otherwise refactoring the code to more easily access deep logic structures

Some tests are better than no tests, and it may be possible to produce credible coverage of existing Automate Domains without having to write new Test Doubles.

### Project Layout

```~/Projects/manageiq-content/content/automate/``` holds the Automate domains to test, and is a database export of them (actually, its the source for the initial database import).

```~/Projects/manageiq-content/spec/content/automate/``` holds the test cases.

The “spec” rake task (the default), will load each of the files in spec/content/automate, that match the naming standard of *_spec.rb. The first line of each test case is invariably require_domain_file, which locates and loads the matching automate .rb.

```~/Projects/manageiq-content/spec/factories/``` holds multi use "factories" of mock objects. Additionally, ```~/Projects/manageiq-content/spec/manageiq/spec/factories/``` holds an extensive collection of pre-built factories from the core ManageIQ project.


### Runtime Walkthrough

Run the test suite with ```bundle rake task```  (the “spec” task is the default). This will load each of the files in spec/content/automate, that match the naming standard of *_spec.rb. ```spec/spec_helper.rb``` loads all the stock manageiq and local factory scripts holding generic mock objects, and defines the ```require_domain_file``` function.

The first line of each test case is invariably require_domain_file, which locates and loads the matching automate .rb.


For discussion purposes, the ```manageiq-content-sample-tests``` has a small collection of sample Automate code,
tests, and factory helpers further described in this document. Link that content into the ```manageiq-content```

In ```Projects/manageiq-content/content/automate```, symlink the top of the Automate domain., e.g.,

```cd ~/Projects/manageiq-content/content/automate```

```ln -s ~/Projects/manageiq-content-sample-tests/automate/Cflab```

Link the test file locations, e.g.,

```cd ~/Projects/manageiq-content/spec/content/automate```

```ln -s ~/Projects/manageiq-content-sample-tests/spec/Cflab```

Link the factory / helper file locations, e.g.,

```cd ~/Projects/manageiq-content/spec/factories```

```ln -s ~/Projects/manageiq-content-sample-tests/factories/Cflab```


**Tip**
You may symlink in your own Automate domain, safely. The code will not be tested unless there is a _spec.rb file that tries to test it.

## Walkthrough of testing code

A sample Automate method I had is a datasource for a dynamic drop down. Suitably updated to be testable, this is `manageiq-content-sample-tests/automate/Cflab/DynamicDialogs/Methods.class/__methods__/list_flavors.rb` :

```
module Cflab
  module DynamicDialogs
    module Methods
      #
      # Method for listing AWS flavors for a drop down.
      #
      # Enforces RBAC
      #
      class List_flavors
        include Cflab::StdLib::Core
        # look at the users current group to get the rbac tag filters applied to that group
        def get_current_group_rbac_array
          @rbac_array = []
          unless @user.current_group.filters.blank?
            @user.current_group.filters['managed'].flatten.each do |filter|
              next unless /(?<category>\w*)\/(?<tag>\w*)$/i =~ filter
              @rbac_array << {category => tag}
            end
          end
          #log(:info, "@user: #{@user.userid} RBAC filters: #{@rbac_array}")
          @rbac_array
        end

        # using the rbac filters check to ensure that templates, clusters, security_groups, etc... are tagged
        def object_eligible?(obj)
          @rbac_array.each do |rbac_hash|
            rbac_hash.each do |rbac_category, rbac_tags|
              Array.wrap(rbac_tags).each {|rbac_tag_entry| return false unless obj.tagged_with?(rbac_category, rbac_tag_entry)}
            end
            true
          end
        end

        #
        # Reasonable languages would call this new() or List_flavors()
        #
        def initialize(handle = $evm)
          @handle = handle
        end

        #
        # Actual entry point the bare script will call into. Outputs into @handle
        #
        def main
          @user = @handle.root['user']
          get_current_group_rbac_array
          dialog_hash = {}

          dump_root()
          log(:info, "I am here")

          @handle.vmdb(:ManageIQ_Providers_Amazon_CloudManager_Flavor).all.each do |flavor|
            next unless flavor.ext_management_system || flavor.enabled
            next unless object_eligible?(flavor)
            @handle.log(:info, "Inspecting flavor: [#{flavor}]")
            dialog_hash[flavor.id] = "#{flavor.name} on #{flavor.ext_management_system.name}"
          end

          if dialog_hash.blank?
            dialog_hash[''] = "< no flavors found >"
            @handle.object['default_value'] = '< no flavors found >'
          else
            @handle.object['default_value'] = dialog_hash.first[0]
          end

          @handle.object["values"] = dialog_hash
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  Cflab::DynamicDialogs::Methods::List_flavors.new.main
end

```

I initial copied a core `manageiq-content` _spec.rb for a different drop down. Update and testing more, this is `manageiq-content-sample-tests/spec/Cflab/DynamicDialogs/Methods.class/__methods__/list_flavors_spec.rb`


```
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

```
You can run a this single test from `manageiq-content` with:

```bundle exec rspec --format documentation spec/content/automate/Cflab/DynamicDialogs/Methods.class/__methods__/list_flavors_spec.rb```

or, the entire test suite with:

```bundle exec rake```

The test results of pass/fail show up in the console, and a code coverage report in `coverage/index.html`

