#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'date'
require 'open-uri'

# require 'open-uri/cached'
# require 'colorize'
# require 'pry'
# require 'csv'

def noko(url)
  Nokogiri::HTML(open(url).read) 
end

@WIKI = 'http://en.wikipedia.org'

def wikilink(a)
  return if a.attr('class') == 'new' 
  @WIKI + a['href']
end

@terms = {
  '2014' => "List_of_current_members_of_the_National_Assembly_of_Botswana",
}

@terms.each do |term, pagename|
  url = "#{@WIKI}/wiki/#{pagename}"
  page = noko(url)
  added = 0

  page.xpath('//table[.//th[text()[contains(.,"Constituency")]]]').each_with_index do |ct, i|
    ct.xpath('tr[td]').each do |member|
      tds = member.xpath('td')

      data = { 
        constituency: tds[1].text.strip,
        name: tds[2].at_xpath('a') ? tds[2].xpath('a').text.strip : tds.first.text.strip,
        wikipedia: tds[2].xpath('a[not(@class="new")]/@href').text.strip,
        party: tds[4].at_xpath('a') ? tds[4].xpath('a').text.strip : tds.last.text.strip,
        source: url,
        term: term,
      }
      data[:wikipedia].prepend @WIKI unless data[:wikipedia].empty?
      data[:constituency] = '' if data[:constituency].include?('Specially elected') or data[:constituency].include?('Ex officio')
      # puts data.values.to_csv
      added += 1
      ScraperWiki.save_sqlite([:name, :term], data)
    end
  end
  warn "Added #{added} for #{term}"
end

