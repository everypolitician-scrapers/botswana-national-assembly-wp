#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko(url)
  Nokogiri::HTML(open(url).read)
end

@WIKI = 'https://en.wikipedia.org'

@pages = [
  'List_of_current_members_of_the_National_Assembly_of_Botswana',
]

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil

@pages.each do |pagename|
  url = "#{@WIKI}/wiki/#{pagename}"
  page = noko(url)

  page.xpath('//table[.//th[text()[contains(.,"Constituency")]]]').each do |ct|
    ct.xpath('tr[td]').each do |member|
      tds = member.xpath('td')

      data = {
        name:         tds[2].at_xpath('a') ? tds[2].xpath('a').text.tidy : tds.first.text.tidy,
        wikiname:     tds[2].xpath('a[not(@class="new")]/@title').text.tidy,
        constituency: tds[1].text.tidy,
        party:        tds[4].at_xpath('a') ? tds[4].xpath('a').text.tidy : tds.last.text.tidy,
        source:       url,
        term:         '2014',
      }
      data[:constituency] = '' if data[:constituency].include?('Specially elected') or data[:constituency].include?('Ex officio')
      puts data.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k }.to_h if ENV['MORPH_DEBUG']
      ScraperWiki.save_sqlite(%i[name term], data)
    end
  end
end
