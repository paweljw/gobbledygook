#!/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'digest/sha1'

Bundler.require(:default)

$stdout.sync = true

dir           = ARGV[0] || './inputs'
prefix_length = ARGV[1] || 2
db_name       = ARGV[3] || "prefixes.db"

File.delete db_name
db = SQLite3::Database.new db_name

rows = db.execute <<-SQL
  create table markov (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    prefix VARCHAR(200),
    word VARCHAR(100),
    times INTEGER DEFAULT 1
  );
SQL

Dir["#{dir}/**/*.txt"].each do |f|
  Formatador.display_line("[green]#{f}[/]")

  file = File.open(f)
  word_array = file.read.gsub("\n", ' ').gsub(/\s+/, ' ').downcase.split(" ")
  progress = Formatador::ProgressBar.new(word_array.count  , :color => "light_blue") { |b| b.opts[:color] = "green" }

  word_array.each_with_index do |word, i|
    prefixes = []

    prefix_length.times do |prefix|
      prefix_word = (i - (prefix_length - prefix))
      prefixes << (prefix_word >= 0 ? word_array[prefix_word] : '')
    end
    prefix = prefixes.join(" ")

    row = db.execute("SELECT id, times FROM markov WHERE word = ? AND prefix = ?;", [ word, prefix ])

    if row.empty?
      db.execute("INSERT INTO markov (prefix, word, times) VALUES (?, ?, ?);", [ prefix, word, 1 ])
    else
      times = row.first.last
      db.execute("UPDATE markov SET times = ? WHERE word = ? AND prefix = ?", [ times+1, word, prefix ])
    end

   progress.increment 
  end
end