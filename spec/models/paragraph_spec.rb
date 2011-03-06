require 'spec_helper'

describe Paragraph do
  include DocumentMacros
  
  describe "top-level positioning" do
    before(:each) do
      @document = Document.create
    end
    
    it "is assigned correctly when pushing paragraphs to a document" do
      paragraphs = Array.new(4){Paragraph.new}
      paragraphs.each{|p| @document.top_level_paragraphs.push(p)}
      @document.save
      @document.reload
      @document.top_level_paragraphs.map(&:position).should == [1, 2, 3, 4]
    end
  end
  
  describe "child paragraphs" do
    before(:each) do
      @document = Document.create
      @paragraph = @document.top_level_paragraphs.create
    end
    
    it "are assigned parentage when pushing child paragraphs to a parent paragraph" do
      child = Paragraph.new
      @paragraph.children.push(child)
      child.reload
      child.parent_id.should == @paragraph.id
    end
    
    it "are associated with their parent's document" do
      child = Paragraph.new
      @paragraph.children.push(child)
      child.reload
      child.document_id.should == @document.id
    end
  end
  
  describe "inserting paragraphs" do
    before(:each) do
      @document = Document.create
      3.times{|i| @document.top_level_paragraphs.create(:body => "Originally #{i + 1}")}
    end
    
    it "inserts a paragraph at the top" do
      p = @document.paragraphs.build(:body => "New", :before_id => @document.top_level_paragraphs.first.id)
      p.save!
      @document.reload
      @document.top_level_paragraphs.map{|p| [p.parent_id, p.position, p.body]}.should == [
        [nil, 1, "New"],
        [nil, 2, "Originally 1"],
        [nil, 3, "Originally 2"],
        [nil, 4, "Originally 3"]
      ]
    end
    
    it "inserts a paragraph at the bottom" do
      p = @document.paragraphs.build(:body => "New", :after_id => @document.top_level_paragraphs.last.id)
      p.save!
      @document.reload
      @document.top_level_paragraphs.map{|p| [p.parent_id, p.position, p.body]}.should == [
        [nil, 1, "Originally 1"],
        [nil, 2, "Originally 2"],
        [nil, 3, "Originally 3"],
        [nil, 4, "New"]
      ]
    end
    
    it "inserts a paragraph in the middle" do
      p = @document.paragraphs.build(:body => "New", :before_id => @document.top_level_paragraphs[1].id)
      p.save!
      @document.reload
      @document.top_level_paragraphs.map{|p| [p.parent_id, p.position, p.body]}.should == [
        [nil, 1, "Originally 1"],
        [nil, 2, "New"],
        [nil, 3, "Originally 2"],
        [nil, 4, "Originally 3"]
      ]
    end
    
    context "into a list of children" do
      before(:each) do
        @first_top_paragraph = @document.top_level_paragraphs.first
        3.times{|i| @document.paragraphs.create(:parent_id => @first_top_paragraph.id, :body => "Child originally #{i + 1}")}
      end
      
      it "inserts a paragraph at the top" do
        p = @document.paragraphs.build(:body => "New", :before_id => @first_top_paragraph.children.first.id)
        p.save!
        @first_top_paragraph.reload
        @first_top_paragraph.children.map{|p| [p.parent_id, p.position, p.body]}.should == [
          [@first_top_paragraph.id, 1, "New"],
          [@first_top_paragraph.id, 2, "Child originally 1"],
          [@first_top_paragraph.id, 3, "Child originally 2"],
          [@first_top_paragraph.id, 4, "Child originally 3"]
        ]
      end

      it "inserts a paragraph at the bottom" do
        p = @document.paragraphs.build(:body => "New", :after_id => @first_top_paragraph.children.last.id)
        p.save!
        @first_top_paragraph.reload
        @first_top_paragraph.children.map{|p| [p.parent_id, p.position, p.body]}.should == [
          [@first_top_paragraph.id, 1, "Child originally 1"],
          [@first_top_paragraph.id, 2, "Child originally 2"],
          [@first_top_paragraph.id, 3, "Child originally 3"],
          [@first_top_paragraph.id, 4, "New"]
        ]
      end

      it "inserts a paragraph in the middle" do
        p = @document.paragraphs.build(:body => "New", :before_id => @first_top_paragraph.children[1].id)
        p.save!
        @first_top_paragraph.reload
        @first_top_paragraph.children.map{|p| [p.parent_id, p.position, p.body]}.should == [
          [@first_top_paragraph.id, 1, "Child originally 1"],
          [@first_top_paragraph.id, 2, "New"],
          [@first_top_paragraph.id, 3, "Child originally 2"],
          [@first_top_paragraph.id, 4, "Child originally 3"]
        ]
      end
    end
  end
  
  describe "deleting" do
    it "deletes its children" do
      @document = Document.create
      @tlp = @document.top_level_paragraphs.create(:body => "top-level")
      3.times{@document.paragraphs.create(:parent_id => @tlp.id)}
      @document.paragraphs.map{|p| [p.parent_id, p.position]}.should == [
        [nil, 1],
        [@tlp.id, 1],
        [@tlp.id, 2],
        [@tlp.id, 3]
      ]
      
      @document.paragraphs.count.should == 4
      @document.reload.top_level_paragraphs.first.destroy
      @document.reload.paragraphs.count.should == 0
    end
  end
  
  describe "indenting" do
    it "makes the paragraph a child of its previous sibling" do
      stub_outline([:one, :two])
      @document.top_level_paragraphs[1].indent!
      @document.reload.outline.should == ['one', ['two']]
    end
    
    it "goes at the bottom of the previous sibling's children" do
      stub_outline([:one, [:sub_one, :sub_two], :two])
      @document.top_level_paragraphs[1].indent!
      @document.reload.outline.should == ['one', ['sub_one', 'sub_two', 'two']]
    end
  end
  
  describe "outdenting" do
    it "inserts itself back into its parent's level" do
      stub_outline([:one, [:two]])
      @document.top_level_paragraphs[0].children[0].outdent!
      @document.reload.outline.should == ['one', 'two']
    end
    
    it "splits its siblings" do
      stub_outline [:one, [:sub_one, :sub_two, :sub_three], :two]
      @document.top_level_paragraphs[0].children[1].outdent!
      @document.reload.outline.should == ['one', ['sub_one'], 'sub_two', ['sub_three'], 'two']
    end
  end
end