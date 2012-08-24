class ParagraphsController < ApplicationController
  before_filter :find_document
  before_filter :find_paragraph, :only => [:edit, :update, :destroy, :indent, :outdent, :move_higher, :move_lower]

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
      redirect_to document_path(@document, :anchor => dom_id(@paragraph)), :notice => "Paragraph added."
    else
      flash.now[:alert] = "There was a problem saving the new paragraph."
      render :action => :new
    end
  end

  def edit
    @paragraph.prepare_for_editing
  end

  def update
    if @paragraph.update_attributes(params[:paragraph])
      respond_to do |format|
        format.html {redirect_to document_path(@document, :anchor => dom_id(@paragraph)), :notice => "Paragraph updated."}
        format.js   {render :partial => 'paragraphs/paragraph_internal', :locals => {:paragraph => @paragraph}}
      end
    else
      flash.now[:alert] = "There was a problem updating the paragraph."
      render :action => :edit
    end
  end

  def destroy
    @paragraph.destroy
    redirect_to document_path(@document), :notice => "Paragraph deleted."
  end

  def indent
    @paragraph.indent!
    redirect_to document_path(@document, :anchor => dom_id(@paragraph))
  end

  def outdent
    @paragraph.outdent!
    redirect_to document_path(@document, :anchor => dom_id(@paragraph))
  end

  def move_lower
    @paragraph.move_lower
    redirect_to document_path(@document, :anchor => dom_id(@paragraph))
  end

  def move_higher
    @paragraph.move_higher
    redirect_to document_path(@document, :anchor => dom_id(@paragraph))
  end

private

  def find_document
    @document = Document.find(params[:document_id])
  end

  def find_paragraph
    @paragraph = @document.paragraphs.find(params[:id])
  end
end
