#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'
require 'wikidata_ids_decorator'

require_relative 'lib/remove_notes'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class MembersPage < Scraped::HTML
  decorator RemoveNotes
  decorator WikidataIdsDecorator::Links

  field :members do
    noko.xpath('//table[.//th[text()[contains(.,"Constituency")]]]//tr[td]').map do |tr|
      fragment(tr => MemberRow).to_h
    end
  end
end

class MemberRow < Scraped::HTML
  field :id do
    tds[2].css('a/@wikidata').map(&:text).map(&:tidy).first
  end

  field :name do
    tds[2].css('a').map(&:text).map(&:tidy).first
  end

  field :wikiname do
    tds[2].xpath('a[not(@class="new")]/@title').text.tidy
  end

  field :constituency do
    return '' if raw_constituency.include?('Specially elected')
    return '' if raw_constituency.include?('Ex officio')
    raw_constituency
  end

  field :party do
    tds[4].css('a').map(&:text).map(&:tidy).first
  end

  field :party_id do
    tds[4].css('a/@wikidata').map(&:text).first
  end

  private

  def tds
    noko.css('td')
  end

  def raw_constituency
    tds[1].text.tidy
  end
end

url = 'https://en.wikipedia.org/wiki/List_of_current_members_of_the_National_Assembly_of_Botswana'
data = MembersPage.new(response: Scraped::Request.new(url: url).response).members.map do |mem|
  mem.merge(term: '2014')
end

data.each { |mem| puts mem.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k }.to_h } if ENV['MORPH_DEBUG']

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
ScraperWiki.save_sqlite(%i[name term], data)
