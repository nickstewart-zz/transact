# PropertyPricesPaidUK
# Created By @nickstewart on 12/07/12

require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-timestamps'
require 'dm-migrations'
require 'slim'
require 'csv'

DataMapper::setup(:default, ENV['HEROKU_POSTGRESQL_GOLD_URL'] || 'postgres://nick@localhost/mydb')

class Property
 
  include DataMapper::Resource

  property :id,		Serial
  property :reg_id,     String
  property :price,	Integer
  property :sold_on,    Date
  property :postcode,   String
  property :type,	String
  property :new_build,	String
  property :duration,	String
  property :paon,	String
  property :saon,	String
  property :street,	String
  property :locality,   String
  property :town,	String
  property :district,	String
  property :county,	String
  property :reg_status, String

end

# Set up reltionships run, sanity checks and migrate
DataMapper.finalize
DataMapper.auto_upgrade!

# Basic HTTP Authentication 
def auth
  @auth ||= Rack::Auth::Basic::Request.new(request.env)
end

def unauthorized!(realm="Short URL Generator")
  headers 'WWW-Authenticate' => %(Basic realm="#{realm}")
  throw :halt, [ 401, 'Authorisation Required' ]
end

def bad_request!
  throw :halt, [ 400, 'Bad Request' ]
end

def authorized?
  request.env['REMOTE_USER']
end

def authorize(username, password)
  if (username=='admin' && password=='admin') then
    true
  else
    false
  end
end

def require_admin
  return if authorized?
  unauthorized! unless auth.provided?
  bad_request! unless auth.basic?
  unauthorized! unless authorize(*auth.credentials)
  request.env['REMOTE_USER'] = auth.username
end

def admin?
  authorized?
end
 
def load_csv(file_name)
  CSV.foreach(file_name, :headers => true) do |row|
    property  = Property.new(reg_id: row[0], price: row[1], sold_on: row[2], postcode: row[3], type: row[4], new_build: row[5], duration: row[6], paon: row[7], saon: row[8], street: row[9], locality: row[10], town: row[11], district: row[12], county: row[13], reg_status: row[14])
    property.save!
  end
end  

get '/' do
  require_admin
  @title = "Property Prices Paid"
  slim :index
end

# Displays a table of all records containing the 
# search string within a specified date range.
# Postcode regex (/(\b[A-Z]{1,2}[0-9][0-9A-Z]{0,1} {1,}\d[A-Z]{2}\b)/)
get '/results' do  
  require_admin  
  @search_string = params[:search_string].upcase
  @date_a = Date.new 2012,params[:month].to_i,1
  @date_b = (@date_a >> 1) - 1
  @title = "Search results for #{@search_string}"
  # Return all records containing the string regardless of character case
  unless @search_string.empty? 
    props_local = Property.all(town: "#{@search_string}") + Property.all(locality: "#{@search_string}") + Property.all(:postcode.like => "#{@search_string}%") 
    @props = props_local.all(:sold_on => @date_a..@date_b)
  else
    # Return empty hash object
    @props = Hash.new
  end
    slim :results
end

__END__

@@ layout 
doctype 5 
html
  head
    title #{@title}
    css:
      body{ font-size: 14px; margin:40px; font-family:  helvetica; }
      table{ width: 100%; text-align: left; }
      table tr:nth-child(even) { background: #ccc; }
      table tr:nth-child(odd) { background: #eee; }
  body
    header
      nav
        a href='/' Home
  == yield

@@ index
h1 #{@title} 

form action="/results" method="get" 
  p
    select name="month"
      option value="01" January
      option value="02" February
      option value="03" March
      option value="04" April
    |  2012
  
  h2 Enter location or post code
  
  p  
    input type="text" name="search_string" 
    input type="Submit" value="Search"

@@ results
h1 #{@title}

- unless @props.empty?
table 
  tr
    th = "Price"
    th = "Sold on"
    th = "PAON"
    th = "SAON"
    th = "Street"
    th = "Locality"
    th = "Town"
    th = "County"
    th = "Postcode"
    th = "Type"
    th = "New"
    th = "Duration"
  - for prop in @props do
    tr
      td = prop.price
      td = prop.sold_on
      td = prop.paon
      td = prop.saon
      td = prop.street
      td = prop.locality
      td = prop.town
      td = prop.county
      td = prop.postcode
      td = prop.type
      td = prop.new_build
      td = prop.duration
- else
  p No records matched your search
