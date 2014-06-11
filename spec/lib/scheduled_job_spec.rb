require 'spec_helper'
require 'pry'

class UnderTest
  include ScheduledJob

  def self.queue_name
    "TESTING"
  end

  def self.time_to_recur(last_run_time)
    "time to recur"
  end

  def perform
  end
end

describe ScheduledJob do

  let(:under_test) { UnderTest.new }

  it "implements the required interface" do
    expect(UnderTest).to respond_to :queue_name
    expect(under_test).to respond_to :perform
    expect(UnderTest).to respond_to :time_to_recur
    expect(UnderTest).to respond_to :random_minutes
  end

  it "adds success to the class" do
    expect(under_test).to respond_to :success
  end

  it "schedules a new job on success" do
    expect(UnderTest).to receive(:schedule_job)
    Delayed::Job.stub(:enqueue)
    underTestJob = double("UnderTestJob");
    underTestJob.stub(:run_at) { DateTime.now.utc }
    underTestJob.stub(:id) { 1 }
    under_test.before underTestJob
    under_test.success underTestJob
  end

  it "adds failure to the class" do
    expect(under_test).to respond_to :failure
  end

  it "logs the error and schedules a job on failure" do
    dummy_job = double("job")
    dummy_job.stub(:id)
    expect(dummy_job).to receive(:update_attributes!)
    expect(ScheduledJob.logger).to receive(:error)
    expect(UnderTest).to receive(:schedule_job)
    Delayed::Job.stub(:enqueue)
    under_test.failure(dummy_job)
  end

  it "adds error to the class" do
    expect(under_test).to respond_to :error
  end

  it "logs on error" do
    job = double("job")
    job.stub(:id) { 4 }
    expect(ScheduledJob.logger).to receive(:warn)
    UnderTest.stub(:schedule_job)
    under_test.error job, nil
  end

    it "wraps delayed job with scheduled_job" do
      job = double("job")
      job.stub(:id) { 4 }
      instance = double("instance")
      UnderTest.stub(:new) { instance }
      expect(Delayed::Job).to receive(:exists?).and_return(false)
      expect(Delayed::Job).to receive(:enqueue).with(instance, run_at: "time to recur", queue: "TESTING")
      UnderTest.schedule_job job
    end

    it "scheduled a job even if there is total failure and an existing job" do
      dummy_job = double("job")
      dummy_job.stub(:id)
      expect(dummy_job).to receive(:update_attributes!)
      expect(Delayed::Job).to receive(:exists?).twice.and_return(false)
      expect(Delayed::Job).to receive(:enqueue).exactly(2).times
      UnderTest.schedule_job
      under_test.failure(dummy_job)
    end

  describe '#random_minutes' do
    it 'returns a random number with a base and delta' do
      expect(UnderTest.random_minutes(60, 10)).to be_within(10 * 60).of(60 * 60)
    end

    it 'returns a random number when called with a negative delta' do
      expect(UnderTest.random_minutes(10, -2)).to be_within(2 * 60).of(10 * 60)
    end

    it 'returns base when called with delta of 0' do
      expect(UnderTest.random_minutes(5, 0)).to be_within(0).of(5 * 60)
    end
  end
end
