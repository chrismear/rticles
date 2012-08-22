class DocumentsController < ApplicationController
  def index
    @documents = Document.all
  end

  def show
    @document = Document.find(params[:id])
  end

  def new
    @document = Document.new
  end

  def create
    @document = Document.new(params[:document])
    if @document.save
      redirect_to document_path(@document), :notice => "New document created."
    else
      flash.now[:alert] = "There was a problem creating your new document."
      render :action => 'new'
    end
  end
end
