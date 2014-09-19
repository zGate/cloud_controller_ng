require "spec_helper"

module VCAP::CloudController
  describe ProcessTypeObserver do
    let(:backends) { double(:backends) }
    let(:one_to_run) { double(:one_to_run) }

    let(:process_type) { ProcessType.make(name: 'foo').save }

    before do
      described_class.configure(backends)
      process_type.app.state = "STARTED"
      process_type.app.save
    end

    it "sends changed app to backend maintaining previous_changes on each object" do
      app = nil
      expect(backends).to receive(:find_one_to_run) do |a|
        app = a
        one_to_run
      end

      expect(one_to_run).to receive(:scale) do
        p app
        expect(app.process_types.first.previous_changes).to include(instances: [0, 5])
        expect(app.process_types.first.instances).to eq(5)
      end

      process_type.app.db.transaction do
        process_type.lock!
        process_type.app.lock!
        process_type.instances = 5
        process_type.save
        process_type.app.save
        ProcessTypeObserver.updated(process_type)
      end
    end
  end
end
