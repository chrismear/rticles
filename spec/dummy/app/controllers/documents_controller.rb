class DocumentsController < ApplicationController
  def index
    @documents = Rticles::Document.all
  end

  def new
    @document = Rticles::Document.new
  end

  def create
    @document = Rticles::Document.new(params[:document])
    if @document.save
      redirect_to document_path(@document), :notice => "New document created."
    else
      flash.now[:alert] = "There was a problem creating your new document."
      render :action => 'new'
    end
  end

  def show
    @document = Rticles::Document.find(params[:id])
  end

  def edit
    @document = Rticles::Document.find(params[:id])
    @editing = true
  end
end
