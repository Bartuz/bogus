require 'spec_helper'

describe Bogus::Shadow do
  let(:object) { Samples::FooFake.new }
  let(:shadow) { Bogus::Shadow.new(object) }

  shared_examples_for "spying on shadows" do
    context "spying" do
      before do
        shadow.run(:foo, "a", "b") rescue nil # for when the method raises an error
      end

      it "returns the called methods" do
        shadow.has_received(:foo, ["a", "b"]).should be_true
      end

      it "does not return true for interactions that did not happen" do
        shadow.has_received(:foo, ["a", "c"]).should be_false
        shadow.has_received(:bar, ["a", "c"]).should be_false
      end
    end
  end

  context "unrecorded interactions" do
    it "returns the object, so that calls can be chained" do
      shadow.run(:foo, "a", "b").should == object
    end

    include_examples "spying on shadows"
  end

  context "interactions that raise exceptions" do
    class SomeWeirdException < StandardError; end

    before do
      shadow.stub.foo("a", "b") { raise SomeWeirdException, "failed!" }
    end

    it "raises the error when called" do
      expect {
        shadow.run(:foo, "a", "b")
      }.to raise_error(SomeWeirdException, "failed!")
    end

    include_examples "spying on shadows"
  end

  context "interactions with no return value" do
    before do
      # this makes the return value block nil
      shadow.stub.__send__(:foo, ["a", "b"])
    end

    it "returns the object" do
      shadow.run(:foo, ["a", "b"]).should == object
    end

    include_examples "spying on shadows"
  end

  context "stubbed interactions" do
    before do
      shadow.stub.foo("a", "b") { "stubbed value" }
    end

    it "returns the stubbed value" do
      shadow.run(:foo, "a", "b").should == "stubbed value"
    end

    it "returns the latest stubbed value" do
      shadow.stub.foo("a", "b") { "stubbed twice" }
      shadow.stub.foo("b", "c") { "different params" }

      shadow.run(:foo, "a", "b").should == "stubbed twice"
      shadow.run(:foo, "b", "c").should == "different params"
    end

    it "returns the default value for non-stubbed calls" do
      shadow.run(:foo, "c", "d").should == object
      shadow.run(:bar).should == object
    end

    it "does not contribute towards unsatisfied interactions" do
      shadow.unsatisfied_interactions.should be_empty
    end

    it "adds required interaction when mocking over stubbing" do
      shadow.mock.foo("a", "b") { "stubbed value" }

      shadow.unsatisfied_interactions.should_not be_empty
    end

    include_examples "spying on shadows"
  end

  context "mocked interactions" do
    before do
      shadow.mock.foo("a", "b") { "mocked value" }
    end

    it "returns the mocked value" do
      shadow.run(:foo, "a", "b").should == "mocked value"
    end

    it "overwrites the stubbed value" do
      shadow.stub.foo("a", "c") { "stubbed value" }
      shadow.mock.foo("a", "c") { "mocked value" }

      shadow.run(:foo, "a", "c").should == "mocked value"
    end

    it "is overwritten by stubbing" do
      shadow.mock.foo("a", "c") { "mocked value" }
      shadow.stub.foo("a", "c") { "stubbed value" }

      shadow.run(:foo, "a", "c").should == "stubbed value"
    end

    it "removes the required interaction when stubbing over mocking" do
      shadow.stub.foo("a", "b") { "stubbed value" }

      shadow.unsatisfied_interactions.should be_empty
    end

    it "returns the default value for non-stubbed calls" do
      shadow.run(:foo, "a", "c").should == object
    end

    it "contributes towards unsatisfied interactions" do
      shadow.unsatisfied_interactions.should  =~ [Bogus::Interaction.new(:foo, ["a", "b"])]
    end

    include_examples "spying on shadows"
  end
end
