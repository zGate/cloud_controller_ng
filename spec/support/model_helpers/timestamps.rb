module ModelHelpers
  shared_examples "timestamps" do |opts|
    before do
      @obj = described_class.make
      @created_at = @obj.created_at
      @obj.updated_at.should be_nil
      @obj.save
    end

    it "should not update the created_at timestamp" do
      expect(@obj.created_at).to eq(@created_at)
    end

    it "should have a recent updated_at timestamp" do
      expect(@obj.updated_at).to be >= @created_at
    end
  end
end
