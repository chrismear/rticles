# encoding: UTF-8

require 'spec_helper'

describe Rticles::Document do

  include DocumentMacros

  describe ".from_yaml" do
    it "works with sub-paragraphs" do
      yaml = File.open('spec/fixtures/simple.yml', 'r')
      expect {
        @document = Rticles::Document.from_yaml(yaml)
      }.to change{Rticles::Paragraph.count}.by(4)
      @document.outline(:with_index => true, :for_display => true).should == [
        '1 Paragraph 1',
        [
          '1.1 Paragraph 1.1',
          '1.2 Paragraph 1.2'
        ],
        '2 Paragraph 2'
      ]
    end

    describe "headings" do
      before(:each) do
        yaml = File.open('spec/fixtures/ips.yml', 'r')
        @document = Rticles::Document.from_yaml(yaml)
        @document.save!
      end

      it "works with headings" do
        @document.top_level_paragraphs.first.should be_heading
      end

      it "works with sub-headings" do
        p = @document.top_level_paragraphs[20]
        p.body.should eq "Borrowing from Members"
        p.heading.should eq 2
      end
    end

    describe "topics" do
      before(:each) do
        yaml = File.open('spec/fixtures/ips.yml', 'r')
        @document = Rticles::Document.from_yaml(yaml)
        @document.save!
      end

      it "saves the topics" do
        objects_paragraph = Rticles::Paragraph.where(:topic => 'objects', :document_id => @document.id).first
        objects_paragraph.should be_present
        objects_paragraph.body.should == "The objects of the Co-operative shall be to carry on the business as a co-operative and to carry on any other trade, business or service and in particular to #rticles#objectives"
      end
    end
  end

  describe "customisations" do
    before(:each) do
      yaml = File.open('spec/fixtures/constitution.yml', 'r')
      @document = Rticles::Document.from_yaml(yaml)
      @document.save!
    end

    describe "insertion" do
      it "is displayed" do
        @document.insertions = {:organisation_name => "The One Click Orgs Association"}
        @document.outline(:for_display => true)[0].should ==
          "This is the constitution (\"Constitution\") of The One Click Orgs Association. (\"The Organisation\")"
      end
    end

    describe "choice" do
      it "is displayed" do
        @document.choices = {:assets => true}
        @document.outline(:for_display => true)[2].should ==
          "The Organisation may hold, transfer and dispose of material assets and intangible assets."
      end
    end

    it "customises the entire document" do
      @document.insertions = {
        :organisation_name => "The One Click Orgs Association",
        :objectives => "developing OCO.",
        :website => "http://gov.oneclickorgs.com/",
        :voting_period => "3 days",
        :general_voting_system_description => "Supporting Votes from more than half of the Members during the Voting Period; or when more Supporting Votes than Opposing Votes have been received for the Proposal at the end of the Voting Period.",
        :constitution_voting_system_description => "Supporting Votes from more than half of the Members are received during the Voting Period; or when more Supporting Votes than Opposing Votes have been received for the Proposal at the end of the Voting Period.",
        :membership_voting_system_description => "Supporting Votes are received from more than two thirds of Members during the Voting Period."
      }
      @document.choices = {
        :assets => true
      }
      @document.outline(:for_display => true).should == [
        "This is the constitution (\"Constitution\") of The One Click Orgs Association. (\"The Organisation\")",
        "The Organisation has the objectives of developing OCO. (\"Objectives\")",
        "The Organisation may hold, transfer and dispose of material assets and intangible assets.",
        "The Organisation uses an electronic system to carry out its governance (\"Governance System\").",
        "The Organisation has one or more members (\"Members\") who support its Objectives.",
        "Each Member nominates an email address at which they will receive important notices from the Organisation (\"Nominated Email Address\").",
        "Members may access the Governance System at the website http://gov.oneclickorgs.com/.",
        "Members may view the current Constitution on the Governance System.",
        "Members may view a register of current Members together with their Nominated Email Addresses on the Governance System.",
        "Members may resign their membership via the Governance System.",
        "Members may jointly make a decision (\"Decision\") relating to any aspect of the Organisation's activities as follows:",
        [
          "Any member may submit a proposal (\"Proposal\") on the Governance System.",
          "A Proposal may be voted on for a period of 3 days starting with its submission (\"Voting Period\").",
          "Members may view all current Proposals on the Governance System.",
          "Members may vote to support (\"Supporting Vote\") or vote to oppose (\"Opposing Vote\") a Proposal on the Governance System during the Proposal's Voting Period.",
          "Members may only vote on Proposals submitted during their membership of the Organisation.",
          "A Decision is made if a Proposal receives Supporting Votes from more than half of the Members during the Voting Period; or when more Supporting Votes than Opposing Votes have been received for the Proposal at the end of the Voting Period.",
          "except that:",
          [
            "The Constitution may only be amended by a Decision where Supporting Votes from more than half of the Members are received during the Voting Period; or when more Supporting Votes than Opposing Votes have been received for the Proposal at the end of the Voting Period."
          ],
          "and",
          [
            "New Members may be appointed (and existing Members ejected) only by a Decision where Supporting Votes are received from more than two thirds of Members during the Voting Period."
          ]
        ],
        "Members may view all Decisions on the Governance System."
      ]
    end
  end

  describe "topic lookup" do
    it "takes into account the current choices" do
      @document = Rticles::Document.create
      @document.top_level_paragraphs.create(:body => "First rule.")
      @document.top_level_paragraphs.create(:body => "#rticles#true#single_shareholding Members may only hold a single share.", :topic => 'shares')
      @document.top_level_paragraphs.create(:body => "#rticles#false#single_shareholding Members may only multiple shares.", :topic => 'shares')
      @document.top_level_paragraphs.create(:body => "#rticles#false#single_shareholding Shares may be applied for and withdrawn at any time", :topic => 'shares')
      @document.top_level_paragraphs.create(:body => "Some other rule.")
      @document.top_level_paragraphs.create(:body => "The company must keep a record of shareholdings.", :topic => 'shares')

      @document.choices[:single_shareholding] = true
      @document.paragraph_numbers_for_topic('shares', true).should eq "2, 4"

      @document.choices[:single_shareholding] = false
      @document.paragraph_numbers_for_topic('shares', true).should eq "2–3, 5"
    end

    it "works for a complex document" do
      yaml = File.open('spec/fixtures/ips.yml', 'r')
      @document = Rticles::Document.from_yaml(yaml)

      @document.choices[:single_shareholding] = true
      @document.paragraph_numbers_for_topic('shares', true).should eq "32"

      @document.choices[:single_shareholding] = false
      @document.paragraph_numbers_for_topic('shares', true).should eq "35–40"
    end

    it "can handle multiple topics" do
      @document = Rticles::Document.create
      @document.top_level_paragraphs.create(:body => "First shares rule", :topic => 'shares')
      @document.top_level_paragraphs.create(:body => "Objectives rule", :topic => 'objectives')
      @document.top_level_paragraphs.create(:body => "Other rule")
      @document.top_level_paragraphs.create(:body => "Second shares rule", :topic => 'shares')

      @document.paragraph_numbers_for_topics(['shares', 'objectives'], true).should eq '1–2, 4'
    end

  end

  describe "numbering config" do
    before(:each) do
      stub_outline([:one, [:sub_one, :sub_two, [:sub_sub_one, :sub_sub_two, :sub_sub_three], :sub_three], :two])
      @paragraph = @document.paragraphs.where(:body => :sub_sub_three).first
    end

    it "defaults to full decimal numbering" do
      @paragraph.full_index.should eq "1.2.3"
    end

    it "allows customisation of the separator" do
      @document.numbering_config.separator = ' '
      @paragraph.full_index(true, nil, @document.numbering_config).should eq "1 2 3"
    end

    it "allows customisation of the list style type" do
      @document.numbering_config[1].style = Rticles::Numbering::DECIMAL
      @document.numbering_config[2].style = Rticles::Numbering::LOWER_ALPHA
      @document.numbering_config[3].style = Rticles::Numbering::LOWER_ROMAN

      @paragraph.full_index(true, nil, @document.numbering_config).should eq "1.b.iii"
    end

    it "allows customisation of the number format" do
      @document.numbering_config.separator = ' '

      @document.numbering_config[2].format = '(#)'

      @paragraph.full_index(true, nil, @document.numbering_config).should eq "1 (2) 3"
    end

    it "allows setting only the innermost number should be printed" do
      @document.numbering_config.innermost_only = true
      @paragraph.full_index(true, nil, @document.numbering_config).should eq "3"
    end
  end

end
