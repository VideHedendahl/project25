require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :sessions


before('/protected/*') do
  p "These are protected_methods"
  if session[:id] ==  nil
    redirect('/ingeninlog')
  end
end

def connect_to_db(path)
  db = SQLite3::Database.new(path)
  db.results_as_hash = true
  return db
end


get('/')  do
  slim(:start)
end

get('/products') do
  user_id = session[:id]
  db = connect_to_db('db/chinook-crud.db')
  result = db.execute("SELECT * FROM products")
 
  if user_id == nil
    slim(:"products/indexoutlog",locals:{products:result})
  else
    slim(:"products/index",locals:{products:result})
  end
end

get('/protected/products/saved') do
  user_id = session[:id]

  db = connect_to_db('db/chinook-crud.db')
  result = db.execute("SELECT * FROM products")
  result2 = db.execute("SELECT * FROM saved")

  slim(:"products/savedindex",locals:{products:result,saved:result2,user_id:user_id})
end

get('/protected/products/new') do
  db = connect_to_db('db/chinook-crud.db')
  result = db.execute("SELECT * FROM companies")
  
  slim(:"products/new",locals:{companies:result})
end

post('/products/new') do
  title = params[:title]
  company_id = params[:company_id].to_i
  db = connect_to_db('db/chinook-crud.db')

  company_check = db.execute("SELECT * FROM companies WHERE CompanyId = ?", company_id).first
  if company_check.nil?
    return "Fel: Leverantör med ID #{company_id} finns inte."
  end

  db.execute("INSERT INTO products (Title, CompanyId) VALUES (?,?)",[title, company_id])
  redirect('/products')
end

post('/products/:id/delete') do
  id = params[:id].to_i
  db = connect_to_db('db/chinook-crud.db')
  db.execute("DELETE FROM products WHERE ProductsId = ?",id)
  redirect('/products')
end

post('/products/:id/save') do
  products_id = params[:id].to_i
  user_id = session[:id]
  db = connect_to_db('db/chinook-crud.db')
  db.execute("INSERT INTO saved (id, product) VALUES (?,?)",[user_id, products_id])
  redirect('/products')
end

post('/saved/:row_number/delete') do
  row_number = params[:row_number].to_i
  db = connect_to_db('db/chinook-crud.db')
  db.execute("DELETE FROM saved WHERE row_number = ?", [row_number])
  redirect('/protected/products/saved')
end

post('/products/:id/update') do
  id = params[:id].to_i
  title = params[:title]
  company_id = params[:CompanyId].to_i
  db = connect_to_db('db/chinook-crud.db')
  db.execute("UPDATE products SET Title=?,CompanyId=? WHERE ProductsId = ?",[title, company_id, id])
  redirect('/products')
end

get('/products/:id/edit') do
  id = params[:id].to_i
  db = connect_to_db('db/chinook-crud.db')
  result = db.execute("SELECT * FROM products WHERE ProductsId = ?",id).first
  slim(:"products/edit",locals:{result:result,id:id})
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
        db = connect_to_db('db/chinook-crud.db')
        db.execute("INSERT INTO users (username,pwdigest) VALUES (?,?)",[username,password_digest])
        redirect('/registrera')
    else
      slim(:"pwEror")
    end
end

get('/loggain') do
    slim(:"login")
end

post('/login') do
    username = params[:username]
    password = params[:password]

    db = connect_to_db('db/chinook-crud.db')
    result = db.execute("SELECT * FROM users WHERE username = ?",username).first
    pwdigest = result["pwdigest"]
    id = result["id"]

    if BCrypt::Password.new(pwdigest) == password
        session[:id] = id
        redirect('/')
    else
      slim(:"pwEror")
    end
end

post('/logout') do
  session[:id] = nil
  redirect('/')
end

get('/products/:id') do
  id = params[:id].to_i
  db = connect_to_db('db/chinook-crud.db')
  result = db.execute("SELECT * FROM products WHERE ProductsId = ?",id).first
  result2 = db.execute("SELECT Name FROM companies WHERE CompanyID IN (SELECT CompanyId FROM products WHERE ProductsId = ?)",id).first
  slim(:"products/show",locals:{result:result,result2:result2})
end

get('/ingeninlog') do
  slim(:"InlgEror")
end