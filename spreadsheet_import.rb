require 'csv'
require 'sqlite3'
db = SQLite3::Database.new('discs.db')

CSV.foreach('spreadsheet.csv') do |row|
  # 0 = OWNER NAME
  # 1 = SHOW TITLE
  # 2 = CONTENTS STRING
  # 4 = TYPE
  # 5 = DONE YES/NO
  break if row[0].nil? # when we reach the end of the valid rows in the sheet

  if row[3] == 'TV' then
    owner     = db.execute('SELECT id FROM owners WHERE name = ?', row[0])[0][0]
    series    = db.execute('SELECT id FROM shows WHERE title = ?', row[1])[0][0]
    if series == [] then
      db.execute('INSERT INTO shows (title) VALUES (?)', row[1])
      db.execute('SELECT id FROM shows WHERE title = ?', row[1])
    end
    epstring  = row[2]
    completed = row[4] == 'Yes' ? 1 : 0
    db.execute('INSERT INTO tv (owner, show, episodes, issued) VALUES (?,?,?,?)', owner, series, epstring, completed)
  elsif row[3] == 'Movie' then
    owner     = db.execute('SELECT id FROM owners WHERE name = ?', row[0])[0][0]
    title     = row[1]
    completed = row[4] == 'Yes' ? 1 : 0
    db.execute('INSERT INTO movies (owner, title, issued) VALUES (?,?,?)', owner, title, completed)
  elsif row[3] == 'CD' then
    owner     = db.execute('SELECT id FROM owners WHERE name = ?', row[0])[0][0]
    title     = row[1]
    completed = row[4] == 'Yes' ? 1 : 0
    db.execute('INSERT INTO cds (owner, title, issued) VALUES (?,?,?)', owner, title, completed)
  end
end

