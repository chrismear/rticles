class ParagraphsController < ApplicationController
  before_filter :find_document
  
  def index
    redirect_to document_path(@document)
  end
  
  def new
    @paragraph = @document.paragraphs.build
    
    @paragraph.before_id = params[:before_id] if params[:before_id]
    @paragraph.after_id = params[:after_id] if params[:after_id]
  end
  
  def create
    @paragraph = @document.paragraphs.build(params[:paragraph])
    if @paragraph.save
      redirect_to document_path(@document), :notice => "Paragraph added."
    else
      flash.now[:alert] = "There was a problem saving the new paragraph."
      render :action => :new
    end
  end
  
  def edit
    @paragraph = @document.paragraphs.find(params[:id])
  end
  
  def update
    @paragraph = @document.paragraphs.find(params[:id])
    if @paragraph.update_attributes(params[:paragraph])
      redirect_to document_path(@document), :notice => "Paragraph updated."
    else
      flash.now[:alert] = "There was a problem updating the paragraph."
      render :action => :edit
    end
  end
  
  def destroy
    @paragraph = @document.paragraphs.find(params[:id])
    @paragraph.destroy
    redirect_to document_path(@document), :notice => "Paragraph deleted."
  end
  
private
  
  def find_document
    @document = Document.find(params[:document_id])
  end
end
