require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'

# begin
#     db = SQLite3::Database.new("db/chinook-crud.db")
#     db.results_as_hash = true
#     puts "Hello World"
#     result = db.execute("SELECT * FROM albums")

#     result.each do |album|
#         puts album["title"]
#     end
# rescue SQLite3::Exception => e
#     puts "Fel: #{e.message}"
# end

get('/')  do
  slim(:start)
end

get('/albums') do
  db = SQLite3::Database.new("db/chinook-crud.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM albums")
  p result
  slim(:"albums/index",locals:{albums:result})
end

get('/albums/saved') do
  db = SQLite3::Database.new("db/chinook-crud.db")
  db.results_as_hash = true
  slim(:"albums/savedindex")
end

get('/albums/new') do
  slim(:"albums/new")
end

post('/albums/new') do
  title = params[:title]
  artist_id = params[:artist_id].to_i
  db = SQLite3::Database.new("db/chinook-crud.db")
  db.execute("INSERT INTO albums (Title, ArtistId) VALUES (?,?)",[title, artist_id])
  redirect('/albums')
end

post('/albums/:id/delete') do
  id = params[:id].to_i
  db = SQLite3::Database.new("db/chinook-crud.db")
  db.execute("DELETE FROM albums WHERE AlbumId = ?",id)
  redirect('/albums')
end

post('/albums/:id/update') do
  id = params[:id].to_i
  title = params[:title]
  artist_id = params[:ArtistId].to_i
  db = SQLite3::Database.new("db/chinook-crud.db")
  db.execute("UPDATE albums SET Title=?,ArtistId=? WHERE AlbumId = ?",[title, artist_id, id])
  redirect('/albums')
end

get('/albums/:id/edit') do
  id = params[:id].to_i
  db = SQLite3::Database.new("db/chinook-crud.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM albums WHERE AlbumId = ?",id).first
  slim(:"albums/edit",locals:{result:result})
end

get('/loggain') do
  slim(:"login")
end

get('/albums/:id') do
  id = params[:id].to_i
  db = SQLite3::Database.new("db/chinook-crud.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM albums WHERE AlbumId = ?",id).first
  result2 = db.execute("SELECT Name FROM Artists WHERE ArtistID IN (SELECT ArtistId FROM Albums WHERE AlbumId = ?)",id).first
  slim(:"albums/show",locals:{result:result,result2:result2})
end


