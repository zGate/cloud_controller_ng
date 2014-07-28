require "spec_helper"

module VCAP::CloudController
  describe FeatureFlag, type: :model do
    let(:feature_flag) { FeatureFlag.make }

    it { is_expected.to have_timestamp_columns }

    describe "Validations" do
      it { is_expected.to validate_presence :name }
      it { is_expected.to validate_uniqueness :name }
      it { is_expected.to validate_presence :enabled }

      context "name validation" do
        context "with a valid name" do
          before do
            TestConfig.config[:feature_flag_defaults] = {
              a_real_value: true,
            }
          end
          it "allows creation of a feature flag that has a corresponding default" do
            subject.name = "a_real_value"
            subject.enabled = false
            expect(subject).to be_valid
          end

        end
        context "with an invalid name" do
          it "does not allow creation of a feature flag that has no corresponding default" do
            subject.name = "not-a-real-value"
            subject.enabled = false
            expect(subject).to_not be_valid
          end
        end
      end
    end

    describe "Serialization" do
      it { is_expected.to export_attributes :name, :enabled }
      it { is_expected.to import_attributes :name, :enabled }
    end

    describe ".some_method_that_we_can_test_in_isolation_and_not_have_to_test_everywhere_we_use_it" do
      before do
        TestConfig.config[:feature_flag_defaults] = {
          :feature_flag_broski => true
        }
      end

      context "when the feature flag is overridden" do
        before do
          FeatureFlag.create(name: "feature_flag_broski", enabled: false)
        end

        it "should return the override value" do
          expect(FeatureFlag.some_method_that_we_can_test_in_isolation_and_not_have_to_test_everywhere_we_use_it("feature_flag_broski")).to eq(false)
        end
      end

      context "when the feature flag is not overridden" do
        it "should return the default value" do
          expect(FeatureFlag.some_method_that_we_can_test_in_isolation_and_not_have_to_test_everywhere_we_use_it("feature_flag_broski")).to eq(true)
        end
      end

      context "when feature flag does not exist" do
        it "blows up somehow" do
          expect {
            FeatureFlag.some_method_that_we_can_test_in_isolation_and_not_have_to_test_everywhere_we_use_it("bogus_feature_flag")
          }.to raise_error()
        end
      end
    end
  end
end
