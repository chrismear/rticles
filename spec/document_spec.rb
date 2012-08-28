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

  describe "customisations" do
    before(:each) do
      yaml = File.open('spec/fixtures/constitution.yml', 'r')
      @document = Rticles::Document.from_yaml(yaml)
      @document.save!
    end

    describe "insertion" do
      it "is displayed" do
        @document.insertions = {:organisation_name => "The One Click Orgs Association"}
        @document.outline(true)[0].should ==
          "This is the constitution (\"Constitution\") of The One Click Orgs Association. (\"The Organisation\")"
      end
    end

    describe "choice" do
      it "is displayed" do
        @document.choices = {:assets => true}
        @document.outline(true)[2].should ==
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
      @document.outline(true).should == [
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

end
