#encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

def init_db
	@db = SQLite3::Database.new 'leprosorium.db'
	@db.results_as_hash = true
end

# выполняется в начале каждого запроса
# before выполняется каждый раз при перезагрузке
# любой страницы
before do 
	# инициализация БД
	init_db
end

# configure вызывается каждый раз при конфигурации приложения:
# когда изменился код программы И перезагрузилась страница
configure do 
	# инициализация БД
	init_db

	# создаёт таблицу если таблица не существует
	@db.execute 'create table if not exists Posts
	(
		id INTEGER PRIMARY KEY AUTOINCREMENT, 
		created_date DATE, 
		content TEXT
	)'

	@db.execute 'create table if not exists Comments
	(
		id INTEGER PRIMARY KEY AUTOINCREMENT, 
		created_date DATE, 
		content TEXT,
		post_id integer
	)'
end

get '/' do
	# выбираем список постов из БД
	@results = @db.execute 'select * from Posts order by id desc'

	erb :index
end

# обработчик get-запроса /new
# (браузер получает страницу с сервера)
get '/new' do
  erb :new
end

# обработчик post-запроса /new
# (браузер отправляет данные на сервер)
post '/new' do
  # получаем переменную из post-запроса
  @content = params[:content]

  if @content.length <= 0
  		@error = 'Type post text'
  		return erb :new
  end

  # сохранение данных в БД
  @db.execute 'insert into Posts (content, created_date) values (?, datetime())', [@content]
  
  # перенаправление на главную страницу
  redirect to '/'
  # возвращаем ответ
  # erb "You typed #{@content}"
end

# /details/4
# как получить параметр
# вывод информации о посте
# универсальный обработчик для разных id
get '/details/:post_id' do
	# получаем переменную из url
	post_id = params[:post_id]

    # получаем список постов
	results = @db.execute 'select * from Posts where id = ?', [post_id]
	@row = results[0]

	# выбираем комментарии для нашего поста
	@comments = @db.execute 'select * from Comments where post_id = ? order by id', [post_id]

	# возвращаем представление details.erb
	return erb :details
end

post '/details/:post_id' do

  post_id = params[:post_id]

  content = params[:content]

  if content.length <= 0
  		@error = 'Type comments text'
  		return erb :new
  end

  # сохранение данных в БД
  @db.execute 'insert into Comments 
  	(
  		content, 
  		created_date, 
  		post_id
	) 
  		values 
	(
		?, 
		datetime(),
		?
	)', [content, post_id]
  
  # перенаправление на главную страницу
  redirect to ('/details/' + post_id)
end

