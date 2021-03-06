require 'promiscuous_black_hole/type_inferrer'
require 'promiscuous_black_hole/eventual_destroyer'

module Promiscuous::BlackHole
  class Record
    include TypeInferrer

    def initialize(table_name, attributes)
      @table_name = table_name
      @attributes = attributes
    end

    def upsert
      existing_record ? update : create
    end

    def destroy
      Promiscuous.debug "Deleting record: #{ table_name }: #{ attributes['id'] }"
      Promiscuous::Subscriber::Worker::EventualDestroyer.postpone_destroy(table_name, attributes['id'])
    end

    def message_version_newer_than_persisted?
      # _v can be nil when records come in via a manual sync
      existing_record.nil? || existing_record[:_v].nil? || existing_record[:_v] <= attributes['_v'].to_i
    end

    private

    attr_reader :table_name, :attributes

    def existing_record
      @existing_record ||= criteria.first
    end

    def update
      Promiscuous.debug "Updating record: [ #{attributes} ]"
      criteria.update(formatted_attributes)
    end

    def create
      Promiscuous.debug "Creating record: #{attributes.values}"
      DB[table_name].insert(formatted_attributes)
    end

    def formatted_attributes
      attrs = {}
      attributes.each { |k, v| attrs[k] = sql_representation_for(v) }
      attrs
    end

    def criteria
      DB[table_name].where('id = ?', attributes['id'])
    end
  end
end
