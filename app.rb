get '/' do
  @users = @db.execute("SELECT name FROM owners ORDER BY name ASC")
  erb :main
end