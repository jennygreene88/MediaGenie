before do
  @db = SQLite3::Database.new('discs.db')
end


get '/' do
  @users = @db.execute('SELECT name FROM owners ORDER BY name ASC')
  erb :main
end


get '/queue' do
  @unissued_movies = @db.execute('SELECT owners.name, movies.title FROM movies JOIN owners ON owners.id = movies.owner WHERE issued = 0')
  erb :queue
end


get '/stats' do
  @issued           = @db.execute('SELECT (SELECT COUNT(*) FROM MOVIES) as count1, (SELECT COUNT(*) FROM tv) as count2')[0].reduce(:+)
  @heaviest_movies  = @db.execute('SELECT name from owners where id = (SELECT owner FROM movies GROUP by owner ORDER BY owner ASC LIMIT 1)')[0][0]
  @heaviest_tv      = @db.execute('SELECT name from owners where id = (SELECT owner FROM tv GROUP BY owner ORDER BY owner ASC LIMIT 1)')[0][0]
  @subscriptions    = @db.execute('SELECT count(*) FROM subscriptions')[0][0]
  @most_discs       = @db.execute('SELECT show FROM (select show, count(*) FROM tv GROUP BY show LIMIT 1)')[0][0]
  @most_popular     = @db.execute('SELECT title FROM (select title, count(*) AS count1 FROM subscriptions GROUP BY title ORDER BY count1 DESC LIMIT 1)')[0][0]
  @users            = @db.execute('SELECT count(*) FROM owners')[0][0]
  @discs_per_day    = sprintf '%.05f', @issued/((Time.now.to_i-Time.new('2014-01-01').to_i)/60/60/24).to_f

  erb :stats
end


get '/:name' do
  # Build a multidimensional array like [[Seinfeld, SQL result set for all Seinfeld discs], [Hannibal, SQL result set for all Hannibal discs]]
  allshows = @db.prepare('SELECT DISTINCT show FROM tv WHERE owner = (SELECT id FROM owners WHERE name = ?)').execute(params[:name])
  @watched_shows = []
  allshows.each {|sub| @watched_shows << [sub[0], @db.prepare('SELECT episodes FROM tv WHERE show = ? AND owner = (SELECT id FROM owners WHERE name = ?)').execute(sub[0], params[:name])]}

  # Build a string of watched shows to use as a header on the resulting page.
  @watch_string_array = []
  @db.prepare('SELECT TITLE FROM subscriptions WHERE name = ?').execute(params[:name]).each { |sub| @watch_string_array << %Q*<a href="/shows/#{URI::encode(sub[0])}">#{sub[0]}</a>* }
  (@watch_string_array.length == 0) ?
      @watch_string_array = 'nothing' :
      @watch_string_array = @watch_string_array.join(", ").gsub(/, (?!.*, )/, ' and ')

  # Get the list of all movies issued for this person.
  @movies = @db.prepare('SELECT TITLE FROM movies WHERE owner = (SELECT id FROM owners WHERE name = ?)').execute(params[:name])

  erb :subs
end


get '/shows/:show' do
  @viewers = []
  @db.prepare('SELECT name FROM subscriptions WHERE title = ? ORDER BY name ASC').execute(params[:show]).each {|viewer| @viewers << viewer[0]}
  @viewers = @viewers.map { |name| "<a href='../../#{name}'>#{name}</a>" }
  @viewers = @viewers.join(", ").gsub(/, (?!.*, )/, ' and ') # the gsub is to replace the final comma in the list with ", and "

  erb :viewers
end