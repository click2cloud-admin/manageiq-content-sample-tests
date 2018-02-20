#
# Description: Core.class StdLib
#

module Cflab
  module StdLib
    module Core

      def initialize(handle = $evm)
        @handle = handle
      end

      def log(level, msg, update_message = false)
        @handle.log(level, "#{msg}")
        @handle.task.message = msg if @task && (update_message || level == 'error')
      end

      def dump_root()
        log(:info, "Begin @handle.root.attributes")
        @handle.root.attributes.sort.each {|k, v| log(:info, "\t Attribute: #{k} = #{v}")}
        log(:info, "End @handle.root.attributes")
        log(:info, "")
      end

    end
  end
end
