require 'spec_helper'

describe Rticles::Document do

  describe ".from_yaml" do
    it "works with sub-paragraphs" do
      yaml = File.open('spec/fixtures/simple.yml', 'r')
      document = Rticles::Document.from_yaml(yaml)
      expect {
        document.save!
      }.to change{Rticles::Paragraph.count}.by(3)
      document.outline.should == [
        'Paragraph 1',
        [
          'Paragraph 1.1'
        ],
        'Paragraph 2'
      ]
    end
  end

  describe "insertion" do
    before(:each) do
      yaml = File.open('spec/fixtures/constitution.yml', 'r')
      @document = Rticles::Document.from_yaml(yaml)
      @document.save!
    end

    it "is displayed" do
      @document.insertions = {:organisation_name => "The One Click Orgs Association"}
      @document.outline(true)[0].should ==
        "This is the constitution (\"Constitution\") of The One Click Orgs Association."
    end
  end
end
