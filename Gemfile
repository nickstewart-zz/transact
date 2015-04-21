source :rubygems
gem 'sinatra'
gem 'dm-core'
gem 'dm-timestamps'
gem 'dm-migrations'
gem 'slim'
gem 'thin'

group :production do
    gem "pg"
    gem "dm-postgres-adapter"
end

group :development, :test do
    gem "sqlite3"
    gem "dm-sqlite-adapter"
end
