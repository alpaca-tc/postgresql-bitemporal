require "bundler/inline"

gemfile(true) do
  source "https://rubygems.org"

  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  gem 'activerecord'
  gem 'pg'
  gem 'activerecord-bitemporal'
  gem 'timecop'
end

require 'active_record'
require 'activerecord-bitemporal'
require 'timecop'

CONFIG = {
  adapter: "postgresql",
  encoding: "unicode",
  pool: 25,
  url: 'postgresql://postgres@localhost:35432',
  password: 'postgres'
}

DATABASE = "hanica-performance"

# DB作成
begin
  ActiveRecord::Base.establish_connection(CONFIG.merge(database: DATABASE))
  ActiveRecord::Base.connection
rescue ActiveRecord::NoDatabaseError
  ActiveRecord::Base.establish_connection(CONFIG)
  ActiveRecord::Base.connection.create_database(DATABASE)
  ActiveRecord::Base.establish_connection(CONFIG.merge(database: DATABASE))
end

# Schema作成
ActiveRecord::Base.connection.create_table(:users, force: true) do |t|
  t.bigint :bitemporal_id
  t.string :name, null: false
  t.datetime :valid_from, null: false
  t.datetime :valid_to, null: false
  t.datetime :transaction_from, null: false
  t.datetime :transaction_to, null: false
end

class User < ActiveRecord::Base
  include ActiveRecord::Bitemporal
end

def count_page_items(table_name)
  ActiveRecord::Base.connection.exec_query("SELECT * FROM heap_page_items(get_raw_page('#{table_name}', 0));" ).to_a.count
end

user = nil

Timecop.freeze('2020-01-01') do
  user = User.create!(name: 'スマ太郎')
end

puts count_page_items('users')

Timecop.freeze('2020-02-01') do
  user.update!(name: 'スマスマ太郎')
end

puts count_page_items('users')

Timecop.freeze('2020-03-01') do
  user.update!(name: 'スマスマスマ太郎')
end

puts count_page_items('users')
