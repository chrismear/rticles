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

    if params[:choices]
      choices = {}
      params[:choices].each do |k, v|
        choices[k] = (v == 'true' ? true : false)
      end
      @document.choices = choices
    end

    if params[:insertions]
      @document.insertions = params[:insertions]
    end

    # Some non-standard numbering set-up, for demonstration
    @document.numbering_config.innermost_only = true

    @document.numbering_config[1].format = '#.'

    @document.numbering_config[2].style = Rticles::Numbering::LOWER_ALPHA
    @document.numbering_config[2].format = '(#)'

    @document.numbering_config[3].style = Rticles::Numbering::LOWER_ROMAN
    @document.numbering_config[3].format = '(#)'
  end

  def edit
    @document = Rticles::Document.find(params[:id])
    @editing = true
  end
end
