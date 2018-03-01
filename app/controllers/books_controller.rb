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
      flash[:message] ="Oops, sorry but you must login below or sign up here first before creating a new book."
      redirect to '/login'
    end
  end

  post '/books' do
    if logged_in?
      taken_book_title = Book.find_by(:title => params[:book][:title])
      if taken_book_title.present?
        flash[:message] = "Sorry, but that book title is already taken, please choose another title."
        redirect to '/books/new'
      end
      @book = current_user.books.build(title: params[:book][:title], topics: params[:book][:topics], year_published: params[:book][:year_published], author_id: params[:book][:author_id])
      if @book.year_published == ""
        @book.year_published = nil
      end
      @book.unknown_author

      params[:booklanguage][:langs].each do |details|
        BookLanguage.create(details)
      end

      BookLanguage.all.each do |booklanguage|
        if booklanguage.book_id == nil
          booklanguage.book_id = Book.last.id
          booklanguage.save
        end
      end

#     Ok, so this 'genre' thingy is just the same as the 'language' one above.
      params[:bookgenre][:gens].each do |details|
        BookGenre.create(details)
      end

      BookGenre.all.each do |bookgenre|
        if bookgenre.book_id == nil
          bookgenre.book_id = Book.last.id
          bookgenre.save
        end
      end

      if @book.save
        redirect to "/books"
      else
        redirect to "/books/new"
      end
    end
  end

  get '/books/:slugtitle' do
    @book = Book.find_by_slugtitle(params[:slugtitle])
    erb :'books/show_book'
  end

  get '/books/:slugtitle/edit' do # This ie exactly the same as "'/books/new' do" above
    @authors = Author.all # this is required to list out all existing authors
    @genres = Genre.all # this is required to list out all existing genres
    @languages = Language.all # this is required to list out all existing languages
    if logged_in?
      @book = Book.find_by_slugtitle(params[:slugtitle])
      if @book && @book.user == current_user
        erb :'books/edit_book'
      else
        redirect to '/books'
      end
    else
      redirect to '/login'
    end
  end

  # ///////////////// everything above is corrected

  patch '/books/:slugtitle' do
    if logged_in?
      @book = Book.find_by_slugtitle(params[:slugtitle])
      raise params.inspect
      title_already_in_use = Book.where(:title => params[:book][:title])
      if title_already_in_use.book_id != @book.book_id
        flash[:message] = "Sorry, but that book title is already taken, please choose another title."
        redirect to '/books/new'
      end
      if @book.user == current_user
        @book.update(title: params[:book][:title], topics: params[:book][:topics], year_published: params[:book][:year_published], author_id: params[:book][:author_id])
        if @book.year_published == ""
          @book.year_published = nil #<= so this activates the <<hypothetical_date_of_publication>> method so if you don't know when the book was published, it will estimate that for you.
        end
        @book.unknown_author         #<= when you create a new author named "Unknown" and then you list
        @book.user_id = session[:user_id]
        @book.save

        # first, you have to delete all BookLanguages with associations of the current book, this is in the "edit" post, but not in the "create" post.
        BookLanguage.all.each do |booklanguage|
          if booklanguage.book_id == @book.id
            booklanguage.delete
            booklanguage.save
          end
        end

        params[:booklanguage][:langs].each do |details|
          BookLanguage.create(details)
        end

        BookLanguage.all.each do |booklanguage|
          if booklanguage.book_id == nil
            booklanguage.book_id = @book.id
            booklanguage.save
          end
        end

#       Ok, so this 'genre' thingy is just the same as the 'language' one above.
        BookGenre.all.each do |bookgenre|
          if bookgenre.book_id == @book.id
            bookgenre.delete
            bookgenre.save
          end
        end

        params[:bookgenre][:gens].each do |details|
          BookGenre.create(details)
        end

        BookGenre.all.each do |bookgenre|
          if bookgenre.book_id == nil
            bookgenre.book_id = @book.id
            bookgenre.save
          end
        end
        erb :'books/show_book'
      end
    end
  end

  delete '/books/:slugtitle/delete' do
    if logged_in?
      @book = Book.find_by_slugtitle(params[:slugtitle])
      if @book.user_id == current_user.id
        @book.delete
        redirect to '/books'
      else
        redirect to '/books'
      end
    else
      redirect to '/login'
    end
  end
end
