# Laddar nödvändiga Ruby-gems för webbapplikationen
require 'sinatra'           # Webbramverk
require 'slim'              # Templating-motor för HTML
require 'sqlite3'           # Databasbibliotek för SQLite
require 'sinatra/reloader'  # Automatisk omladdning under utveckling
require 'bcrypt'            # Hashning av lösenord för säkerhet

enable :sessions            # Aktiverar sessionshantering (för inloggning m.m.)

# En "before filter" som körs innan alla routes som börjar med /protected
# Används för att skydda känsliga sidor så att bara inloggade användare kommer åt dem
before('/protected/*') do
  p "These are protected_methods"
  if session[:id] == nil
    redirect('/ingeninlog') # Om användaren inte är inloggad, omdirigera
  end
end

# Hjälpfunktion som ansluter till databasen och aktiverar hash-resultat
def connect_to_db(path)
  db = SQLite3::Database.new(path)
  db.results_as_hash = true
  return db
end

# Startsidan
get('/') do
  slim(:start)
end

# Visar alla produkter, olika vy om användaren är inloggad eller inte
get('/products') do
  user_id = session[:id]
  db = connect_to_db('db/chinook-crud.db')
  result = db.execute("SELECT * FROM products")
 
  if user_id == nil
    slim(:"products/indexoutlog",locals:{products:result}) # Utloggad vy
  else
    slim(:"products/index",locals:{products:result})       # Inloggad vy
  end
end

# Visar en lista på produkter som användaren har sparat (kräver inloggning)
get('/protected/products/saved') do
  user_id = session[:id]
  db = connect_to_db('db/chinook-crud.db')
  result = db.execute("SELECT * FROM products")
  result2 = db.execute("SELECT * FROM saved")

  slim(:"products/savedindex",locals:{products:result,saved:result2,user_id:user_id})
end

# Formulär för att skapa en ny produkt (visar även alla företag som alternativ)
get('/protected/products/new') do
  db = connect_to_db('db/chinook-crud.db')
  result = db.execute("SELECT * FROM companies")
  slim(:"products/new",locals:{companies:result})
end

# Lägger till en ny produkt i databasen, med kontroll att företaget existerar
post('/products/new') do
  title = params[:title]
  company_id = params[:company_id].to_i
  db = connect_to_db('db/chinook-crud.db')

  # Säkerhetskontroll: finns företaget?
  company_check = db.execute("SELECT * FROM companies WHERE CompanyId = ?", company_id).first
  if company_check.nil?
    return "Fel: Leverantör med ID #{company_id} finns inte."
  end

  # Lägger till produkt
  db.execute("INSERT INTO products (Title, CompanyId) VALUES (?,?)",[title, company_id])
  redirect('/products')
end

# Tar bort en produkt med givet ID
post('/products/:id/delete') do
  id = params[:id].to_i
  db = connect_to_db('db/chinook-crud.db')
  db.execute("DELETE FROM products WHERE ProductsId = ?", id)
  redirect('/products')
end

# Sparar en produkt i användarens "sparade" lista
post('/products/:id/save') do
  products_id = params[:id].to_i
  user_id = session[:id]
  db = connect_to_db('db/chinook-crud.db')
  db.execute("INSERT INTO saved (id, product) VALUES (?,?)", [user_id, products_id])
  redirect('/products')
end

# Tar bort en sparad produkt (via radnummer i saved-tabellen)
post('/saved/:row_number/delete') do
  row_number = params[:row_number].to_i
  db = connect_to_db('db/chinook-crud.db')
  db.execute("DELETE FROM saved WHERE row_number = ?", [row_number])
  redirect('/protected/products/saved')
end

# Uppdaterar en produkts titel
post('/products/:id/update') do
  id = params[:id].to_i
  title = params[:title]
  company_id = params[:CompanyId].to_i
  db = connect_to_db('db/chinook-crud.db')
  db.execute("UPDATE products SET Title=?, CompanyId=? WHERE ProductsId = ?", [title, company_id, id])
  redirect('/products')
end

# Formulär för att redigera en viss produkt
get('/products/:id/edit') do
  id = params[:id].to_i
  db = connect_to_db('db/chinook-crud.db')
  result = db.execute("SELECT * FROM products WHERE ProductsId = ?", id).first
  slim(:"products/edit",locals:{result:result,id:id})
end

# Visar registreringsformulär
get('/registrera') do
  slim(:"register")
end

# Registrerar ny användare med lösenord som hashats med BCrypt
post('/users/new') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]

  if password == password_confirm
    password_digest = BCrypt::Password.create(password)  # Hashar lösenordet
    db = connect_to_db('db/chinook-crud.db')
    db.execute("INSERT INTO users (username, pwdigest) VALUES (?,?)", [username, password_digest])
    redirect('/registrera')
  else
    slim(:"pwEror") # Lösenorden matchade inte
  end
end

# Visar inloggningsformulär
get('/loggain') do
  slim(:"login")
end

# Loggar in användaren genom att jämföra lösenord med hash i databasen
post('/login') do
  username = params[:username]
  password = params[:password]

  db = connect_to_db('db/chinook-crud.db')
  result = db.execute("SELECT * FROM users WHERE username = ?", username).first
  pwdigest = result["pwdigest"]
  id = result["id"]

  if BCrypt::Password.new(pwdigest) == password
    session[:id] = id
    redirect('/')
  else
    slim(:"pwEror") # Felaktigt lösenord
  end
end

# Loggar ut användaren genom att rensa sessionen
post('/logout') do
  session[:id] = nil
  redirect('/')
end

# Visar detaljerad information om en specifik produkt
get('/products/:id') do
  id = params[:id].to_i
  db = connect_to_db('db/chinook-crud.db')
  result = db.execute("SELECT * FROM products WHERE ProductsId = ?", id).first
  result2 = db.execute("SELECT Name FROM companies WHERE CompanyID IN (SELECT CompanyId FROM products WHERE ProductsId = ?)", id).first
  slim(:"products/show",locals:{result:result,result2:result2})
end

# Visar felmeddelande när en användare försöker gå till en skyddad route utan att vara inloggad
get('/ingeninlog') do
  slim(:"InlgEror")
end