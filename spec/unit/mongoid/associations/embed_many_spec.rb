require "spec_helper"

describe Mongoid::Associations::EmbedMany do

  before do
    @attributes = { "addresses" => [
      { "_id" => "street-1", "street" => "Street 1", "state" => "CA" },
      { "_id" => "street-2", "street" => "Street 2" } ] }
    @document = stub(:raw_attributes => @attributes, :add_observer => true, :update => true)
  end

  describe "#[]" do

    before do
      @association = Mongoid::Associations::EmbedMany.new(
        @document,
        Mongoid::Associations::Options.new(:name => :addresses)
      )
    end

    context "when the index is present in the association" do

      it "returns the document at the index" do
        @association[0].should be_a_kind_of(Address)
        @association[0].street.should == "Street 1"
      end

    end

    context "when the index is not present in the association" do

      it "returns nil" do
        @association[3].should be_nil
      end

    end

  end

  describe "#<<" do

    before do
      @association = Mongoid::Associations::EmbedMany.new(
        @document,
        Mongoid::Associations::Options.new(:name => :addresses)
      )
      @address = Address.new
    end

    it "adds the parent document before appending to the array" do
      @association << @address
      @association.length.should == 3
      @address._parent.should == @document
    end

    it "allows multiple additions" do
      @association << @address
      @association << @address
      @association.length.should == 4
    end

  end

  describe "#build" do

    context "setting the parent relationship" do

      before do
        @person = Person.new
      end

      it "happens before any other operation" do
        address = @person.addresses.build(:set_parent => true, :street => "Madison Ave")
        address._parent.should == @person
        @person.addresses.first.should == address
      end

    end

    context "when a type is not provided" do

      before do
        @association = Mongoid::Associations::EmbedMany.new(
          @document,
          Mongoid::Associations::Options.new(:name => :addresses)
        )
      end

      it "adds a new document to the array with the suppied parameters" do
        @association.build({ :street => "Street 1" })
        @association.length.should == 3
        @association[2].should be_a_kind_of(Address)
        @association[2].street.should == "Street 1"
      end

      it "returns the newly built object in the association" do
        address = @association.build({ :street => "Yet Another" })
        address.should be_a_kind_of(Address)
        address.street.should == "Yet Another"
      end

    end

    context "when a type is provided" do

      before do
        @association = Mongoid::Associations::EmbedMany.new(
          @document,
          Mongoid::Associations::Options.new(:name => :shapes)
        )
      end

      it "instantiates a class of the type" do
        circle = @association.build({ :radius => 100 }, Circle)
        circle.should be_a_kind_of(Circle)
        circle.radius.should == 100
      end

    end

  end

  describe "#create" do

    context "when a type is not provided" do

      before do
        @association = Mongoid::Associations::EmbedMany.new(
          @document,
          Mongoid::Associations::Options.new(:name => :addresses)
        )
        @address = mock(:parentize => true, :write_attributes => true)
        Address.expects(:instantiate).returns(@address)
        @address.expects(:run_callbacks).with(:create).yields
      end

      it "builds and saves a new object" do
        @address.expects(:save).returns(true)
        address = @association.create({ :street => "Yet Another" })
        address.should == @address
      end

    end

    context "when a type is provided" do

      before do
        @association = Mongoid::Associations::EmbedMany.new(
          @document,
          Mongoid::Associations::Options.new(:name => :shapes)
        )
        @circle = mock(:parentize => true, :write_attributes => true)
        Circle.expects(:instantiate).returns(@circle)
        @circle.expects(:run_callbacks).with(:create).yields
      end

      it "instantiates a class of that type" do
        @circle.expects(:save).returns(true)
        circle = @association.create({ :radius => 100 }, Circle)
        circle.should == @circle
      end

    end

  end

  describe "#create!" do

    context "when validations pass" do

      before do
        @association = Mongoid::Associations::EmbedMany.new(
          @document,
          Mongoid::Associations::Options.new(:name => :addresses)
        )
        @address = mock(:parentize => true, :write_attributes => true, :errors => [])
        Address.expects(:instantiate).returns(@address)
        @address.expects(:run_callbacks).with(:create).yields
      end

      it "builds and saves a new object" do
        @address.expects(:save).returns(true)
        address = @association.create!({ :street => "Yet Another" })
        address.should == @address
      end
    end

    context "when validations fail" do

      before do
        @association = Mongoid::Associations::EmbedMany.new(
          @document,
          Mongoid::Associations::Options.new(:name => :addresses)
        )
        @address = mock(:parentize => true, :write_attributes => true, :errors => [ "test" ])
        Address.expects(:instantiate).returns(@address)
        @address.expects(:run_callbacks).with(:create).yields
      end

      it "builds and saves a new object" do
        @address.expects(:save).returns(false)
        lambda {
          @association.create!({ :street => "Yet Another" })
        }.should raise_error(Mongoid::Errors::Validations)
      end
    end
  end

  describe "#concat" do

    before do
      @association = Mongoid::Associations::EmbedMany.new(
        @document,
        Mongoid::Associations::Options.new(:name => :addresses)
      )
      @address = Address.new
    end

    it "adds the parent document before appending to the array" do
      @association.concat [@address]
      @association.length.should == 3
      @address._parent.should == @document
    end

  end

  describe "#clear" do

    before do
      @association = Mongoid::Associations::EmbedMany.new(
        @document,
        Mongoid::Associations::Options.new(:name => :addresses)
      )
      @address = Address.new
      @association << @address
    end

    it "clears out the association" do
      @association.clear
      @association.size.should == 0
    end

  end

  describe "#find" do

    before do
      @association = Mongoid::Associations::EmbedMany.new(
        @document,
        Mongoid::Associations::Options.new(:name => :addresses)
      )
    end

    context "when finding all" do

      it "returns all the documents" do
        @association.find(:all).should == @association
      end

    end

    context "when finding by id" do

      it "returns the document in the array with that id" do
        address = @association.find("street-2")
        address.should_not be_nil
      end

    end

  end

  describe "#first" do

    context "when there are elements in the array" do

      before do
        @association = Mongoid::Associations::EmbedMany.new(
          @document,
          Mongoid::Associations::Options.new(:name => :addresses)
        )
      end

      it "returns the first element" do
        @association.first.should be_a_kind_of(Address)
        @association.first.street.should == "Street 1"
      end

    end

    context "when the array is empty" do

      before do
        @association = Mongoid::Associations::EmbedMany.new(
          Person.new,
          Mongoid::Associations::Options.new(:name => :addresses)
        )
      end

      it "returns nil" do
        @association.first.should be_nil
      end

    end

  end

  describe "#initialize" do

    context "when no extension exists" do

      before do
        @canvas = stub(:raw_attributes => { "shapes" => [{ "_type" => "Circle", "radius" => 5 }] }, :update => true)
        @association = Mongoid::Associations::EmbedMany.new(
          @canvas,
          Mongoid::Associations::Options.new(:name => :shapes)
        )
      end

      it "creates the classes based on their types" do
        circle = @association.first
        circle.should be_a_kind_of(Circle)
        circle.radius.should == 5
      end

    end

    context "when an extension is in the options" do

      before do
        @person = Person.new
        @block = Proc.new do
          def extension
            "Testing"
          end
        end
        @association = Mongoid::Associations::EmbedMany.new(
          @person,
          Mongoid::Associations::Options.new(:name => :addresses, :extend => @block)
        )
      end

      it "adds the extension module" do
        @association.extension.should == "Testing"
      end

    end

  end

  describe ".instantiate" do

    it "delegates to new" do
      Mongoid::Associations::EmbedMany.expects(:new).with(@document, @options)
      Mongoid::Associations::EmbedMany.instantiate(@document, @options)
    end

  end

  describe "#length" do

    context "#length" do

      it "returns the length of the delegated array" do
        @association = Mongoid::Associations::EmbedMany.new(
          @document,
          Mongoid::Associations::Options.new(:name => :addresses)
        )
        @association.length.should == 2
      end

    end

  end

  describe ".macro" do

    it "returns :embed_many" do
      Mongoid::Associations::EmbedMany.macro.should == :embed_many
    end

  end

  describe "#nested_build" do

    before do
      @association = Mongoid::Associations::EmbedMany.new(
        @document,
        Mongoid::Associations::Options.new(:name => :addresses)
      )
    end

    it "returns the newly built object in the association" do
      @association.nested_build({ "0" => { :street => "Yet Another" } })
      @association.size.should == 3
      @association.last.street.should == "Yet Another"
    end

  end

  describe "#method_missing" do

    context "when the association class has a criteria class method" do

      before do
        @association = Mongoid::Associations::EmbedMany.new(
          @document,
          Mongoid::Associations::Options.new(:name => :addresses)
        )
      end

      it "returns the criteria" do
        @association.california.should be_a_kind_of(Mongoid::Criteria)
      end

      it "sets the documents on the criteria" do
        criteria = @association.california
        criteria.documents.should == @association.entries
      end

      it "returns the scoped documents" do
        addresses = @association.california
        addresses.size.should == 1
        addresses.first.should be_a_kind_of(Address)
        addresses.first.state.should == "CA"
      end

    end

    context "when no class method exists" do

      before do
        @association = Mongoid::Associations::EmbedMany.new(
          @document,
          Mongoid::Associations::Options.new(:name => :addresses)
        )
      end

      it "delegates to the array" do
        @association.entries.size.should == 2
      end

    end

  end

  describe "#paginate" do

    before do
      @association = Mongoid::Associations::EmbedMany.new(
        @document,
        Mongoid::Associations::Options.new(:name => :addresses)
      )
      @options = { :page => 1, :per_page => 10 }
      @criteria = mock
    end

    it "creates a criteria and paginates it" do
      Mongoid::Criteria.expects(:translate).with(Address, @options).returns(@criteria)
      @criteria.expects(:documents=).with(@association.target)
      @criteria.expects(:paginate).returns([])
      @association.paginate(@options).should == []
    end
  end

  describe "#push" do

    before do
      @association = Mongoid::Associations::EmbedMany.new(
        @document,
        Mongoid::Associations::Options.new(:name => :addresses)
      )
      @address = Address.new
    end

    it "adds the parent document before appending to the array" do
      @association.push @address
      @association.length.should == 3
      @address._parent.should == @document
    end

    it "appends the document to the end of the array" do
      @association.push(Address.new)
      @association.length.should == 3
    end

  end

  describe ".update" do

    before do
      @address = Address.new(:street => "Madison Ave")
      @person = Person.new(:title => "Sir")
      @association = Mongoid::Associations::EmbedMany.update(
        [@address],
        @person,
        Mongoid::Associations::Options.new(:name => :addresses)
      )
    end

    it "parentizes the child document" do
      @address._parent.should == @person
    end

    it "sets the attributes of the child on the parent" do
      @person.attributes[:addresses].should ==
        [{ "_id" => "madison-ave", "street" => "Madison Ave", "_type" => "Address" }]
    end

    it "returns the association proxy" do
      @association.target.size.should == 1
    end

  end

end
