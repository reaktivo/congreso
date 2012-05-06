# encoding: utf-8
require_relative "congreso/version"

require 'open-uri'
require 'awesome_print'
require 'nokogiri'
require 'cgi'

module Congreso

  BaseURL = 'http://gaceta.diputados.gob.mx'
  VotesURL = 'http://gaceta.diputados.gob.mx/voto61/ordi32/lanordi32.php3?'

  VoteFields = ["Favor", "Contra", "Abstención", "Quórum", "Ausente"]
  Ausente = "Ausente"
  Abstencion = "Abstención"

  class Scraper

    def initialize
      @abscences = {}
      doc = Nokogiri::HTML open("#{BaseURL}/Gaceta/Votaciones/61/vot_a3segundo.html")
      parts = doc.css('body > *').to_a
      parts.delete_if {|part| part.content == "\u00A0"}
      dates = {}
      current_date = nil
      parts.each do |part|
        if part.name == "font"
          current_date = part.content
          dates[current_date] = []
        end
        if part.name == "ul"
          law = part.css("li").children[0].content
          approved = !!part.content.match("Aprobado")
          votation_link = part.css('a').find {|a| a["href"].match 'Votaciones'}
          link = BaseURL + votation_link['href']
          voting_data = parse_voting open(link)
          data = { :text => law, :approved => approved }.merge!(voting_data)
          dates[current_date].push data
        end
      end
      ap dates
    end

    def parse_voting(body)
      doc = Nokogiri::HTML(body)
      data = { absent: nil, abstain: nil }
      values = { evento: doc.css("input[name=evento]")[0]["value"]}
      doc.css('table tr').each do |tr|
        tds = tr.css('td')
        if tds and tds[0]
          [Ausente, Abstencion].each do |type|
            if tds[0].content.strip.index(type) == 0
              input = tds[1].css('input')[0]
              values[input["name"]] = input["value"]
              body = open(VotesURL + values.to_params)
              doc = Nokogiri::HTML(body)
              if type == Ausente
                data[:absent] = structure(doc, /Diputados del? (.+) que estuvieron ausentes: (.+)/)
              elsif type == Abstencion
                data[:abstain] = structure(doc, /Diputados del? (.+) que se abstuvieronde votar: (.+)/)
              end
            end
          end
        end
      end
      data
    end

    def structure(doc, regex)
      data = {}
      doc.css('center').each do |el|
        matches = el.content.match regex
        if matches
          party = matches[1]
          data[party] = []
          el.parent.css('table td').each do |td|
            congressmen = td.content.split(/\d+:/).compact.reject { |d| d.empty? }
            data[party].push(*congressmen)
          end
        end
      end
      data
    end

  end
end




class Hash
  def to_params
    params = ''
    stack = []

    each do |k, v|
      if v.is_a?(Hash)
        stack << [k,v]
      elsif v.is_a?(Array)
        stack << [k,Hash.from_array(v)]
      else
        params << "#{k}=#{v}&"
      end
    end

    stack.each do |parent, hash|
      hash.each do |k, v|
        if v.is_a?(Hash)
          stack << ["#{parent}[#{k}]", v]
        else
          params << "#{parent}[#{k}]=#{v}&"
        end
      end
    end

    params.chop!
    params
  end

  def self.from_array(array = [])
    h = Hash.new
    array.size.times do |t|
      h[t] = array[t]
    end
    h
  end

end