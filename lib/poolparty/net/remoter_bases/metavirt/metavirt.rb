=begin rdoc
 The metavirt remoter base send all commands to a RESTful HTTP server that implements the commands
  
=end
require 'restclient'

module PoolParty
  module Remote
    class Metavirt < Remote::RemoterBase
      include Dslify
      include ::PoolParty::CloudResourcer
      
      default_options(
        :authorized_keys => nil,
        :remoter_base    => :libvirt,
        :server_config   => {}
        )
      
      def initialize(o={}, &block)
        using o[:remoter_base], o.delete(:remote_base) if o.has_key?(:remoter_base)
        super
        set_vars_from_options remote_base.dsl_options
      end
      
      def method_missing(m, args, &blk)
        remote_base.respond_to?(m) ? remote_base.send(m, args, &blk) : super
      end
      
      def authorized_keys
        keypair.public_key
      end
      
      def remote_base(n=nil)
        if n.nil?
          @remote_base
        else
          @remote_base = n
        end
      end
      
      def image_id
        dsl_options[:remote_base].image_id
      end
      
      #Setup server instance that will talk to metavirt webservice
      def server
        if @server
          @server
        else
          opts = { :content_type  =>'application/json', 
                   :accept        => 'application/json',
                   :host          => 'http://localhost',
                   :port          => '3000'
                  }.merge(server_config)
          @uri = "#{opts.delete(:host)}:#{opts.delete(:port)}"
          @server = RestClient::Resource.new( @uri, opts)
        end
      end
      
      def self.launch_new_instance!(o={})
        new_instance(o).launch_new_instance!
      end
      def launch_new_instance!(o={})
        opts = to_hash.merge(o)
        result = JSON.parse(server['/run-instance'].put(opts.to_json)).symbolize_keys!
        @id = result[:instance_id]
        MetavirtInstance.new result
      end
      
      # Terminate an instance by id
      def self.terminate_instance!(o={})
        new(nil, o).terminate_instance!
      end
      def terminate_instance!(o={})
        opts = to_hash.merge(o)
        raise "id or instance_id must be set before calling describe_instace" if !id(o)
        MetavirtInstance.new server["/instances/#{id(o)}"].delete.json_parse
      end

      # Describe an instance's status, must pass :vmx_file in the options
      def self.describe_instance(o={})
        new(o).describe_instance
      end
      def describe_instance(o={})
        opts = to_hash.merge(o)
        raise "id or instance_id must be set before calling describe_instace" if !id(o)
        MetavirtInstance.new server["/instances/#{id(o)}"].get.json_parse
      end

      def self.describe_instances(o={})
        new(o).describe_instances
      end
      def describe_instances(o={})
        opts = to_hash.merge(o)
        list = JSON.parse( server["/instances/"].get ).collect{|i| i.symbolize_keys!}
        list.collect{|l| MetavirtInstance.new l}
      end
      
      def to_hash
        dsl_options.merge(:remote_base => remote_base.to_hash)
      end
      
      private
      def id(o={})
       @id = ( o[:id] || o[:instance_id] || @id || dsl_options[:id] || dsl_options[:instance_id] )
      end
      
    end
  end
end