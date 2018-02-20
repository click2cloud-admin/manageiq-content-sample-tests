# require '/home/jwarnica/Projects/manageiq-content/content/automate/Cflab/StdLib/Core.class/__methods__/core.rb'
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
