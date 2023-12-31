#!/usr/bin/env ruby
# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'json'
require_relative '../quality/util/bitable'

class WikiPod
  class User
    attr_accessor :id, :name, :en_name, :email

    def initialize(hash)
      return unless hash.is_a? Hash
      @id = hash['id']
      @name = hash['name']
      @en_name = hash['en_name']
      @email  = hash['email']
    end

    def to_bitable_field
      hash = {}
      hash['id'] = id unless id.nil?
      hash['name'] = name unless name.nil?
      hash['en_name'] = en_name unless en_name.nil?
      hash['email'] = email unless email.nil?
      hash
    end
  end

  attr_accessor :name, :biz, :layer, :desc, :status, :owners

  # @type [Hash] hash
  # @return [WikiPod]
  def self.parse(hash)
    return unless hash.is_a? Hash
    fields = hash['fields']
    return unless fields.is_a? Hash
    name = fields['组件']
    return if name.nil? || name.empty?

    pod = WikiPod.new
    pod.name = name

    pod.biz = fields['业务']&.strip
    pod.layer = fields['层级']&.strip
    pod.desc = fields['组件描述']&.strip
    pod.status = fields['状态']

    # owners
    owner_raws = fields['Owner']
    if owner_raws.is_a? Array
      pod.owners = owner_raws.map { |raw| User.new raw  }.compact
    end

    pod
  end

  # @return [Array<WikiPod>]
  def self.load_from_server
    bitable = Bitable.new(token: 'bascnPVfKD6PoXM3WJIDNt5NwEe', table_id: 'tblwOALpOa0rqeqQ')
    bitable.load_records(recursive: true).map { |hash| WikiPod::parse hash }.compact
  end

  # @param [String] path
  def self.dump_owners(path:)
    wiki_pods = load_from_server
    pod_owner_list = wiki_pods.filter_map do |pod|
      next nil if pod.owners.nil? || pod.owners.empty?

      { 'pod_name' => pod.name, 'owners' => pod.owners.map(&:to_bitable_field) }
    end
    File.open(path, 'w') do |file|
      file.write JSON.pretty_generate(pod_owner_list)
    end
  end
end
