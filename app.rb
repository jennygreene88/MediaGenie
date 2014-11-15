before do
  @db = SQLite3::Database.new("discs.db")
end


get '/' do
  @users = @db.execute("SELECT name FROM owners ORDER BY name ASC")
  erb :main
end


get '/queue' do
  @unissued_movies = @db.execute("SELECT owners.name, movies.title FROM movies JOIN owners ON owners.id = movies.owner WHERE issued = 0")
  erb :queue
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


get '/:name' do
  @allshows = @db.prepare("select distinct show from tv where owner = (SELECT id FROM owners WHERE name = ?)").execute(params[:name])
  
  # Build a multidimensional array like [[Seinfeld, SQL result set for all Seinfeld discs], [Hannibal, SQL result set for all Hannibal discs]]
  @watched_shows = []
  @allshows.each {|sub| @watched_shows << [sub[0], @db.prepare("SELECT episodes FROM tv WHERE show = ? AND owner = (SELECT id FROM owners WHERE name = ?)").execute(sub[0], params[:name])]}

  # Build a string of watched shows to use as a header on the resulting page.
  @watch_string_array = []
  @db.prepare("select title from subscriptions where name = ?").execute(params[:name]).each do |sub| 
    title = URI::encode(sub[0])
    @watch_string_array << %Q*<a href="/shows/#{title}">#{sub[0]}</a>*
  end
  if @watch_string_array.length == 0 then
    @watch_string_array = "nothing"
  else
    @watch_string_array = @watch_string_array.join(", ").gsub(/, (?!.*, )/, " and ")
  end

  # Get the list of all movies burnt for this person.
  @movies = @db.prepare("select title from movies where owner = (SELECT id FROM owners WHERE name = ?)").execute(params[:name])

  erb :subs
end