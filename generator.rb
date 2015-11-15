#!/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'digest/sha1'

Bundler.require(:default)

def process_word(word)
  return 'I' if word[0] == 'i' && word.length < 3
  word
end

def process_sentence(sentence)
  sentence << "." unless SENTENCE_ENDS.include? sentence [-2..-1]
  sentence.gsub(',.', '.')
  sentence[0] = sentence[0].upcase
  sentence
end

SENTENCE_ENDS = [ '.', '!' ]

db_name       = ARGV[1] || "prefixes.db"
max_tokens    = ARGV[2] || 10
max_sentences = ARGV[3] || 10

db = SQLite3::Database.new db_name

max_sentences.times do |sentence|
  tokens = 0

  # select a random input prefix
  row = db.execute("SELECT * FROM markov ORDER BY RANDOM() LIMIT 1;")
  prefix = row.first[1]

  sentence = prefix.dup.gsub(".", "")
  while tokens < max_tokens do
    # select all entries for this prefix
    words = db.execute("SELECT word, times FROM markov WHERE prefix = ?;", [ prefix ])
    break if words.empty?
    words = words.inject([]) { |array, entry| array << ([entry.first]*entry.last) }.flatten

    word = words.sample

    word = process_word(word)

    sentence << " #{word}"

    # special rules
    break if SENTENCE_ENDS.include? word[-2..-1]

    prefix = prefix.split(" ")[1..-1]
    prefix << word
    prefix = prefix.join(" ")
    tokens += 1
  end
  sentence = process_sentence(sentence)
  puts sentence
end