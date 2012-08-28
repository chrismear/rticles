require 'spec_helper'

describe Rticles::Paragraph do
  include DocumentMacros

  describe "top-level positioning" do
    before(:each) do
      @document = Rticles::Document.create
    end

    it "is assigned correctly when pushing paragraphs to a document" do
      paragraphs = Array.new(4){Rticles::Paragraph.new}
      paragraphs.each{|p| @document.top_level_paragraphs.push(p)}
      @document.save
      @document.reload
      @document.top_level_paragraphs.map(&:position).should == [1, 2, 3, 4]
    end
  end

  describe "child paragraphs" do
    before(:each) do
      @document = Rticles::Document.create
      @paragraph = @document.top_level_paragraphs.create
    end

    it "are assigned parentage when pushing child paragraphs to a parent paragraph" do
      child = Rticles::Paragraph.new
      @paragraph.children.push(child)
      child.reload
      child.parent_id.should == @paragraph.id
    end

    it "are associated with their parent's document" do
      child = Rticles::Paragraph.new
      @paragraph.children.push(child)
      child.reload
      child.document_id.should == @document.id
    end
  end

  describe "inserting paragraphs" do
    before(:each) do
      @document = Rticles::Document.create
      3.times{|i| @document.top_level_paragraphs.create(:body => "Originally #{i + 1}")}
    end

    it "inserts a paragraph at the top" do
      paragraph = @document.paragraphs.build(:body => "New", :before_id => @document.top_level_paragraphs.first.id)
      paragraph.save!
      @document.reload
      @document.top_level_paragraphs.map{|p| [p.parent_id, p.position, p.body]}.should == [
        [nil, 1, "New"],
        [nil, 2, "Originally 1"],
        [nil, 3, "Originally 2"],
        [nil, 4, "Originally 3"]
      ]
    end

    it "inserts a paragraph at the bottom" do
      paragraph = @document.paragraphs.build(:body => "New", :after_id => @document.top_level_paragraphs.last.id)
      paragraph.save!
      @document.reload
      @document.top_level_paragraphs.map{|p| [p.parent_id, p.position, p.body]}.should == [
        [nil, 1, "Originally 1"],
        [nil, 2, "Originally 2"],
        [nil, 3, "Originally 3"],
        [nil, 4, "New"]
      ]
    end

    it "inserts a paragraph in the middle" do
      paragraph = @document.paragraphs.build(:body => "New", :before_id => @document.top_level_paragraphs[1].id)
      paragraph.save!
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
        paragraph = @document.paragraphs.build(:body => "New", :before_id => @first_top_paragraph.children.first.id)
        paragraph.save!
        @first_top_paragraph.reload
        @first_top_paragraph.children.map{|p| [p.parent_id, p.position, p.body]}.should == [
          [@first_top_paragraph.id, 1, "New"],
          [@first_top_paragraph.id, 2, "Child originally 1"],
          [@first_top_paragraph.id, 3, "Child originally 2"],
          [@first_top_paragraph.id, 4, "Child originally 3"]
        ]
      end

      it "inserts a paragraph at the bottom" do
        paragraph = @document.paragraphs.build(:body => "New", :after_id => @first_top_paragraph.children.last.id)
        paragraph.save!
        @first_top_paragraph.reload
        @first_top_paragraph.children.map{|p| [p.parent_id, p.position, p.body]}.should == [
          [@first_top_paragraph.id, 1, "Child originally 1"],
          [@first_top_paragraph.id, 2, "Child originally 2"],
          [@first_top_paragraph.id, 3, "Child originally 3"],
          [@first_top_paragraph.id, 4, "New"]
        ]
      end

      it "inserts a paragraph in the middle" do
        paragraph = @document.paragraphs.build(:body => "New", :before_id => @first_top_paragraph.children[1].id)
        paragraph.save!
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
      @document = Rticles::Document.create
      @tlp = @document.top_level_paragraphs.create(:body => "top-level")
      3.times{@document.paragraphs.create(:parent_id => @tlp.id)}
      @document.paragraphs.map{|p| [p.parent_id, p.position]}.should eq [
        [nil, 1],
        [@tlp.id, 1],
        [@tlp.id, 2],
        [@tlp.id, 3]
      ]

      @document.paragraphs.count.should eq 4
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

  describe "index" do
    before(:each) do
      @document = Rticles::Document.create
      @document.top_level_paragraphs.create(:body => 'one')
      @document.top_level_paragraphs.create(:body => 'Heading one', :heading => 1)
      @document.top_level_paragraphs.create(:body => 'two')
    end

    it "ignores headings" do
      @document.paragraphs[0].index.should eq 1
      @document.paragraphs[2].index.should eq 2
    end

    it "returns nil for headings" do
      @document.paragraphs[1].index.should be_nil
    end
  end

  describe "generating HTML" do
    before(:each) do
      @document = Rticles::Document.create
      @document.top_level_paragraphs.create(:body => "A Simple Constitution", :heading => 1)
      @document.top_level_paragraphs.create(:body => "For demonstration purposes only", :heading => 2, :continuation => true)

      @document.top_level_paragraphs.create(:body => "This is the first rule.")

      p = @document.top_level_paragraphs.create(:body => "This is the second rule, which applies when:")
      @document.paragraphs.create(:body => "This condition;", :parent_id => p.id)
      @document.paragraphs.create(:body => "and this condition.", :parent_id => p.id)
      @document.top_level_paragraphs.create(:body => "except when it is a Full Moon.", :continuation => true)

      @document.top_level_paragraphs.create(:body => "This is the third rule.")

      @document.top_level_paragraphs.create(:body => "This is the fourth rule.")
      @document.top_level_paragraphs.create(:body => "And finally...", :heading => 2)
      @document.top_level_paragraphs.create(:body => "This is the final rule.")
    end

    it "works" do
      expected_html = <<-EOF
      <section>
        <hgroup>
          <h1>A Simple Constitution</h1>
          <h2>For demonstration purposes only</h2>
        </hgroup>
        <ol>
          <li>1 This is the first rule.</li>
          <li>
            2 This is the second rule, which applies when:
            <ol>
              <li>2.1 This condition;</li>
              <li>2.2 and this condition.</li>
            </ol>
            except when it is a Full Moon.
          </li>
          <li>3 This is the third rule.</li>
          <li>4 This is the fourth rule.</li>
        </ol>
        <h2>And finally...</h2>
        <ol>
          <li>5 This is the final rule.</li>
        </ol>
      </section>
      EOF

      html = @document.to_html

      html.should be_equivalent_to(expected_html)
    end
  end
end
