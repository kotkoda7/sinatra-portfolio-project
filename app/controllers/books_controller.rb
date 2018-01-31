class BooksController < ApplicationController
  get '/books' do
    @books = Book.all
    erb :'books/books'
  end

  get '/books/new' do
    @authors = Author.all # this is required to list out all existing authors
    @genres = Genre.all # this is required to list out all existing genres
    @languages = Language.all # this is required to list out all existing languages
    if logged_in?
      erb :'books/create_book'
    else
      redirect to '/validation-failure'
    end
  end

  get '/books/:slugtitle' do
    @book = Book.find_by_slugtitle(params[:slugtitle])
    erb :'books/show_book'
  end

  post '/books' do
#   raise params.inspect
#     {
#       "book"=>
#         {"title"=>"AAdfarks", "topics"=>"funny story", "year_published"=>"", "author_id"=>"6"}
#          ,
#       "booklanguage"=>
#         {"language.id"=>"4"}
#     }

    @book = Book.create(title: params[:book][:title], topics: params[:book][:topics], year_published: params[:book][:year_published], author_id: params[:book][:author_id])

    params[:booklanguage][:langs].each do |details|
      BookLanguage.create(details)
    end

    BookLanguage.all.each do |booklanguage|
      if booklanguage.book_id == nil
        booklanguage.book_id = Book.last.id
        booklanguage.save
      end
    end

  #  @booklanguage = BookLanguage.create(book_id: @book.id, language_id: params[:booklanguage]["language.id"])
    @bookgenre = BookGenre.create(book_id: @book.id, genre_id: params[:bookgenre]["genre.id"])
    redirect to :'books'
  end
end
