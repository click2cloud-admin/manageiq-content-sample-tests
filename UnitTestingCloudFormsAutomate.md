# Introduction
This document is an introduction into the process of unit testing CloudForms Automation methods.

Inspired by Christian Jung teaser introduction to some CloudForms Automation best practices at [http://www.jung-christian.de/post/2017/10/automate-best-practice/](http://www.jung-christian.de/post/2017/10/automate-best-practice/), this serves to expand on that, and provided details of that for administrator/developer of CloudForms who perhaps isn’t familiar with the tools and concepts discussed.

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

#On to testing

##Some Theory

This document does not serve as an introduction to Unit Testing, Test Driven Development, or how to write good tests. Far superior references exist and are outside the scope of this effort, however, a quick recap is necessary.

First consider the difference of _testing_ code and _testable_ code. Theoretical concerns of the halting problem aside, in practice, automated testing of code realistically require code to be written to be testable, to be testable by a particular test framework toolset, and to be testable within some project specific conventions and build environment.

Our goal here is _unit_ testing code. We are not simulating entire workflows. Initially we can only possibly expect to test for conditions we expect to happen. As code enters manual full testing, and use with real users and live systems, more and more unimaginable user inputs and API responses will be encountered. As the _unit_ is improved to handle what yesterday we knew to be impossible, the _unit test_ is improved to simulate the impossible.

CloudForms Automate code, by its design purpose, manipulates a large number of components outside the control of the Automate developer, i.e. the rest of CloudForms outside the sandbox (and the external providers it connects to), and any remote APIs that Automate may directly interact with. In _Unit_ testing we don't want to run those external systems because it is slow, may have real world impact and/or take prohibitive amount of time to actually produce a real test environment, and as Automate developers anything from fixing a datastore full to segfault conditions are outside our control, authority or responsibility. Besides, Automate should gracefully handle someone forgetting to buy disks even (or especially!) if that person is you.

_Unit_ testing implies that code outside the Unit Under Test (UUT) is replaced with a "mock" version. These mocks can be manipulated by the tester to an exact known state - good, bad, or impossible. Thus we can test both success and failure conditions (and all conditions between) without either producing a dirty database, intentionally hacking a database to be dirty, or yanking hardware for the unobtanium lab environment.

The simulated modules accessed are called "mocks", and we can use and manipulate the mock objects provided by the base ManageIQ project, and create our own for testing other integration points.

The ultimate output of Unit Testing is a report showing test results (pass/fail), and code coverage reports. Test results obviously show if the UUT operates as the test desires. The code coverage reports display what code has been run, and what has not. How well it has been tested is a different question, but an Automate method where a test exercises 100% of the lines & branches at least is guaranteed not to have syntax errors. Unit testing will also not help you convince a project manager that it meets a requirement, though a rigorous testing framework does provide evidence that _you_ did not break anything when you touched it.

_Test Driven Development_ is the idea of writing test cases before and with the run time code. ```rspec```, the Ruby testing framework takes this concept further, describing it as "Behaviour Driven Development": describing a desired behaviour of a unit (Automate method) through a unit test.

<!-- TODO: talk about writing mocks when I write a mock -->

## Back to reality

For testing of any piece of existing Automate code, it will requires at least mechanical and trivial changes into a testable form. A complicated automate method may well require extensive refactoring to get to 100% line coverage, let alone 100% functional coverage. Don’t expect to _test_ your code without a little bit of effort to make it _testable_ code. 

Most of what Automate code does is call to external resources, be it the core code accessible from evm, the systems indirectly accessible through evm, or external APIs.

Net new automate methods, built with a test driven development methodology will have these conventions in place implicity. It may seem odd to write more functional code (and ugly boilerplate code at that), and at least as much test code, but when the practical CloudForms alternative is often waiting 15 minutes for a provision to fail, a rigorous test suite up front is less time overall.

Broadly, testing an automate method from the wild will consists of doing the following:

* Wrapping the core code in module/class decorations

* Wrapping the main code in a main() function definition

* Adding an initialize() method to allow injecting a mock $evm into @handle

* Tweaking any existing code to use @handle _viz_ $evm

* Writing spec files (the tests themselves) to test the code

* Optionally, otherwise refactoring the code to more easily access deep logic structures

* For advanced gamers, it is possible to mock out even external APIs, but that is a for a future post or revision of this

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
You may symlink in your own Automate domain, at any time, safely. The code will not be tested unless there is a _spec.rb file that tries to test it.

**Further Pedantic Aside**: Ruby modules, classes and methods have little to do with Automate namespaces, classes, instances and methods. The concepts are overloaded, and refactoring to the new format, you still will not be able to directly instantiate or call other Automate “methods” post-conversion.

## Walkthrough of testing code

Or at least play along and use my Method.

I give you ```CFLAB/datastore/DynamicDialogs/Methods.class/__methods__/list_flavors.rb``` :

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

        def log(level, msg, update_message = false)
          @handle.log(level, "#{msg}")
          @task.message = msg if @task && (update_message || level == 'error')
        end

        def dump_root()
          log(:info, "Begin @handle.root.attributes")
          @handle.root.attributes.sort.each {|k, v| log(:info, "\t Attribute: #{k} = #{v}")}
          log(:info, "End @handle.root.attributes")
          log(:info, "")
        end

        # look at the users current group to get the rbac tag filters applied to that group
        def get_current_group_rbac_array
          @rbac_array = []
          unless @user.current_group.filters.blank?
            @user.current_group.filters['managed'].flatten.each do |filter|
              next unless /(?<category>\w*)\/(?<tag>\w*)$/i =~ filter
              @rbac_array << {category => tag}
            end
          end
          log(:info, "@user: #{@user.userid} RBAC filters: #{@rbac_array}")
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
I created an initial _spec.rb file by copying ```Projects/manageiq-content/spec/content/automate/ManageIQ/Infrastructure/VM/Transform/Import.class/__methods__/list_tag_categories_spec.rb``` into ```Projects/CFLAB/specs/Cflab/DynamicDialogs/Methods.class/__methods__/list_flavors_spec.rb```

This required some tweaking and I got:

```
require_domain_file

describe Cflab::DynamicDialogs::Methods::List_flavors do
  let(:user) {FactoryGirl.create(:user_with_email_and_group)}
  let(:svc_model_user) {MiqAeMethodService::MiqAeServiceUser.find(user.id)}

  let(:ems) {FactoryGirl.create(:ems_amazon)}

  let(:t2_small_flavor) do
    FactoryGirl.create(:flavor_amazon, :ems_id => ems.id,
                       :name => 't2.small',
                       :cloud_subnet_required => false)
  end

  let(:m2_small_flavor) do
    FactoryGirl.create(:flavor_amazon, :ems_id => ems.id,
    :name => 'm2.small',
    :cloud_subnet_required => false)
  end

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

  it 'should list flavors' do

    ems.flavors << m2_small_flavor
    ems.flavors << t2_small_flavor


    # expect(ae_service.object['sort_by']).to eq(:description)
    # expect(ae_service.object['data_type']).to eq(:string)
    # expect(ae_service.object['required']).to eq(true)

    flavors = {}
    ems.flavors.each do |flavor|
      puts ">> [#{flavor}]"
      flavors[flavor.id] = "#{flavor.name} on #{ems.name}"
    end

    described_class.new(ae_service).main

    # puts flavors
    # puts ems.flavors.length

    expect(ae_service.object['values']).to eq(flavors)
    expect(ae_service.object['values'].length).to eq(MiqAeMethodService::MiqAeServiceFlavor.all.length)
  end

  it 'show show no flavors' do

    flavors = {'' => '< no flavors found >'}

    described_class.new(ae_service).main

    expect(ae_service.object['values']).to eq(flavors)
    expect(ae_service.object['values'].length).to eq(1)
  end
end

```
You can run a this single test from ```manageiq-content``` with:

```bundle exec rspec --format documentation spec/content/automate/Cflab/DynamicDialogs/Methods.class/__methods__/list_flavors_spec.rb```

or, the entire test suite with:

```bundle exec rake```

