# -*- coding: utf-8 -*-

require 'thor'
require 'isono'

module Dcmgr::Cli
class Storage < Base
  namespace :storage
  include Dcmgr::Models
  
  desc "add NODE_ID", "Register a new storage pool node"
  method_option :uuid, :type => :string, :aliases => "-u", :desc => "The uuid for the new storage pool."
  method_option :base_path, :type => :string, :aliases => '-b', :required => true, :desc => "Base path to store volume files"
  method_option :snapshot_base_path, :type => :string, :aliases => '-n', :required => true, :desc => "Base path to store snapshot files"
  method_option :disk_space, :type => :numeric, :aliases => "-s", :required => true, :desc => "Amount of disk size to be exported (in MB)."
  method_option :transport_type, :type => :string, :aliases => "-t", :default=>'iscsi', :desc => "Transport type [iscsi]"
  method_option :ipaddr, :type => :string, :aliases => "-i", :required=>true, :desc => "IP address of transport target"
  method_option :storage_type, :type => :string, :aliases => "-o", :default=>'zfs', :desc => "Storage type [zfs]"
  method_option :account_id, :type => :string, :default=>'a-shpool', :aliases => "-a", :desc => "The account ID to own this."
  def add(node_id)
    unless (options[:force] == false && Isono::Models::NodeState.exists?(:node_id=>options[:node_id]))
      abort("Node ID is not registered yet: #{options[:node_id]}")
    end

    fields = {:node_id=>options[:node_id],
              :offering_disk_space=>options[:disk_space],
              :transport_type=>options[:transport_type],
              :storage_type=>options[:storage_type],
              :export_path=>options[:base_path],
              :snapshot_base_path => options[:snapshot_base_path],
              :ipaddr=>options[:ipaddr],
              :account_id=>options[:account_id],
    }
    fields.merge!({:uuid => options[:uuid]}) unless options[:uuid].nil?
    
    puts super(StoragePool,fields)
  end

  desc "del UUID", "Deregister a storage pool node"
  def del(uuid)
    sp = StoragePool[uuid] || raise(Thor::Error.new("Unknown storage pool node: #{uuid}"))
    sp.delete
  end

  desc "shownodes", "Show node (agents)"
  def shownodes
    nodes = Isono::Models::NodeState.filter.all
    
    puts ERB.new(<<__END, nil, '-').result(binding)
Node ID\tState
<%- nodes.each { |row| -%>
<%= row.node_id %>\t<%= row.state %>
<%- } -%>
__END
  end
end
end
