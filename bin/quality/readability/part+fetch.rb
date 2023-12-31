#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative './part'
require_relative './proj'

class Part
  def update_latest_issue_count!
    fetcher = ::Proj::Fetcher.new
    self.latest_issue_count = fetcher.fetch_issue_count(
      proj_id: proj.id,
      vers_id: proj.latest_vers_id,
      path: path
    )
    self
  end

  def update_base_issue_count!
    fetcher = ::Proj::Fetcher.new
    self.base_issue_count = fetcher.fetch_issue_count(
      proj_id: proj.id,
      vers_id: proj.base_vers_id,
      path: path
    )
    self
  end
end

class Part::Proj
  # @param [Array<String>] proj_names
  # @param [String] base_group_ver_id
  # @return [Array<Part::Proj>]
  def self.load_by_names(proj_names, base_group_ver_id)
    fetcher = Proj::Fetcher.new
    base_metrics_list = fetcher.fetch_vers_metrics(base_group_ver_id)
    latest_metrics_list = fetcher.fetch_vers_metrics

    proj_names.filter_map do |proj_name|
      base_metrics = base_metrics_list.find { |m| m.proj_name == proj_name }
      latest_metrics = latest_metrics_list.find { |m| m.proj_name == proj_name }
      next if base_metrics.nil? || latest_metrics.nil?

      proj = Part::Proj.new
      proj.id = base_metrics.proj_id
      proj.name = base_metrics.proj_name
      proj.path = base_metrics.proj_name
      proj.base_vers_id = base_metrics.vers_id
      proj.latest_vers_id = latest_metrics.vers_id
      proj
    end
  end

  # @param [String] proj_name
  # @param [String] base_group_ver_id
  # @return [Part::Proj]
  def self.load_by_name(proj_name, base_group_ver_id)
    load_by_names([proj_name], base_group_ver_id).first
  end
end