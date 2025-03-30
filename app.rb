require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'


get('/')  do
  slim(:start)
end

get('/products') do
  db = SQLite3::Database.new("db/chinook-crud.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM albums")
  p result
  slim(:"products/index",locals:{albums:result})
end

get('/products/saved') do
  db = SQLite3::Database.new("db/chinook-crud.db")
  db.results_as_hash = true
  slim(:"products/savedindex")
end

get('/products/new') do
  slim(:"products/new")
end

post('/products/new') do
  title = params[:title]
  artist_id = params[:artist_id].to_i
  db = SQLite3::Database.new("db/chinook-crud.db")
  db.execute("INSERT INTO albums (Title, ArtistId) VALUES (?,?)",[title, artist_id])
  redirect('/products')
end

post('/products/:id/delete') do
  id = params[:id].to_i
  db = SQLite3::Database.new("db/chinook-crud.db")
  db.execute("DELETE FROM albums WHERE AlbumId = ?",id)
  redirect('/products')
end

post('/products/:id/update') do
  id = params[:id].to_i
  title = params[:title]
  artist_id = params[:ArtistId].to_i
  db = SQLite3::Database.new("db/chinook-crud.db")
  db.execute("UPDATE albums SET Title=?,ArtistId=? WHERE AlbumId = ?",[title, artist_id, id])
  redirect('/products')
end

get('/products/:id/edit') do
  id = params[:id].to_i
  db = SQLite3::Database.new("db/chinook-crud.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM albums WHERE AlbumId = ?",id).first
  slim(:"products/edit",locals:{result:result})
end

get('/registrera') do
  slim(:"register")
end

post('/users/new') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]

    if (password == password_confirm)
        password_digest = BCrypt::Password.create(password)
        db = SQLite3::Database.new("db/chinook-crud.db")
        db.execute("INSERT INTO users (username,pwdigest) VALUES (?,?)",[username,password_digest])
        redirect('/registrera')
    else
        "Lösenorden matchade inte"
    end
end

get('/products/:id') do
  id = params[:id].to_i
  db = SQLite3::Database.new("db/chinook-crud.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM albums WHERE AlbumId = ?",id).first
  result2 = db.execute("SELECT Name FROM Artists WHERE ArtistID IN (SELECT ArtistId FROM Albums WHERE AlbumId = ?)",id).first
  slim(:"products/show",locals:{result:result,result2:result2})
end


