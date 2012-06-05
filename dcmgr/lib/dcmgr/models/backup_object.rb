# -*- coding: utf-8 -*-

module Dcmgr::Models
  class BackupObject < AccountResource
    taggable 'bo'
    accept_service_type

    many_to_one :backup_storage
    plugin ArchiveChangedColumn, :histories
    # TODO put logs to accounting log.

    subset(:alives, {:deleted_at => nil})
    
    class RequestError < RuntimeError; end

    def after_initialize
      super
      self.object_key ||= self.canonical_uuid
    end
    
    def self.entry_new(account, size, &blk)
      bo = self.new
      bo.account_id = account.canonical_uuid
      bo.size = size.to_i
      bo.state = :creating
      blk.call(bo)
      bo.save
    end

    def entry_delete
      if self.state.to_sym != :available
        raise RequestError, "invalid delete request"
      end
      self.state = :deleting
      self.save_changes
      self
    end

    # override Sequel::Model#delete not to delete rows but to set
    # delete flags.
    def delete
      self.state = :deleted if self.state != :deleted
      self.deleted_at ||= Time.now
      self.save
    end

    def uri
      self.backup_storage.base_uri + self.object_key
    end
  end
end