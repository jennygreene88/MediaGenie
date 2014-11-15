before do
  @db = SQLite3::Database.new("discs.db")
end


get '/' do
  @users = @db.execute("SELECT name FROM owners ORDER BY name ASC")
  erb :main
end


get '/stats' do
  @issued = @db.execute("SELECT (SELECT COUNT(*) FROM MOVIES) as count1, (SELECT COUNT(*) FROM tv) as count2")[0].reduce(:+)
  @heaviest_movies = @db.execute("SELECT name from owners where id = (SELECT owner from movies group by owner order by owner asc limit 1)")[0][0]
  @heaviest_tv = @db.execute("SELECT name from owners where id = (SELECT owner from tv group by owner order by owner asc limit 1)")[0][0]
  @subscriptions = @db.execute("SELECT count(*) FROM subscriptions")[0][0]
  @most_discs = @db.execute("select show from (select show, count(*) from tv group by show limit 1)")[0][0]
  @most_popular = @db.execute("select title from (select title, count(*) as count1 from subscriptions group by title order by count1 desc limit 1)")[0][0]
  @users = @db.execute("select count(*) from owners")[0][0]
  erb :stats
end