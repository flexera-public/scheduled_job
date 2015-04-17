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

class Test < UnderTest
end

describe ScheduledJob do
  before { ScheduledJob.configure { |config| config.jobs = nil } }

  let(:under_test) { UnderTest.new }

  describe '.config' do
    context 'without .configure call' do
      before do
        # Reload ScheduledJob class
        Object.send :remove_const, :ScheduledJob if Object.const_defined? :ScheduledJob
        load 'scheduled_job.rb'
      end

      it 'has default value' do
        expect(ScheduledJob.config).not_to be_nil
      end
    end
  end

  describe 'job config' do
    let(:job_class) { UnderTest }
    let(:job_count) { 1 }

    let(:configure) do
      lambda do
        ScheduledJob.configure do |config|
          config.jobs = { job_class => { count: job_count } }
        end
      end
    end

    context 'job class is a class' do
      it 'considers the jobs hash valid' do
        expect(configure).not_to raise_error
      end
    end

    context 'job class is a string' do
      let(:job_class) { 'UnderTest' }

      it 'considers the jobs hash valid' do
        expect(configure).not_to raise_error
      end
    end

    context 'job class is a symbol' do
      let(:job_class) { :UnderTest }

      it 'considers the jobs hash valid' do
        expect(configure).not_to raise_error
      end
    end

    context 'job class is not a class, string, or symbol' do
      let(:job_class) { 1 }

      it 'raises ConfigError' do
        expect(configure).to raise_error(ScheduledJob::ConfigError)
      end
    end

    context 'job count is not a non-negative integer' do
      let(:job_count) { -1 }

      it 'raises ConfigError' do
        expect(configure).to raise_error(ScheduledJob::ConfigError)
      end
    end
  end

  describe 'reschedule' do
    before do
      ScheduledJob.configure do |config|
        config.jobs = {
          UnderTest => { count: 1 },
          :Test     => { count: 5 }
        }
      end
    end

    it 'calls reschedule on all config jobs up to the job count limit' do
      expect(UnderTest).to receive(:schedule_job).once
      expect(Test).to receive(:schedule_job).exactly(5).times
      ScheduledJob.reschedule
    end
  end

  describe 'fast mode' do
    before { expect(Delayed::Job).to receive(:where).and_return([]) }

    context 'when the job is not in run fast mode' do
      it 'uses the value from time to recur' do
        expect(Delayed::Job).to receive(:enqueue).with(anything, {
          :run_at => UnderTest.time_to_recur(nil),
          :queue  => UnderTest.queue_name
        })
        UnderTest.schedule_job
      end
    end

    context 'when the job is in run fast mode' do
      before do
        ScheduledJob.configure do |config|
          config.fast_mode = lambda { |_| true }
        end
      end
      it 'uses the current time plus one second' do
        time = Time.now.utc
        allow(Time).to receive_message_chain(:now, :utc) { time }

        expect(Delayed::Job).to receive(:enqueue).with(anything, {
          :run_at => time + 1,
          :queue  => UnderTest.queue_name
        })
        UnderTest.schedule_job
      end
    end
  end

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
    allow(Delayed::Job).to receive(:enqueue)
    underTestJob = double("UnderTestJob");
    allow(underTestJob).to receive(:run_at) { DateTime.now.utc }
    allow(underTestJob).to receive(:id) { 1 }
    under_test.before underTestJob
    under_test.success underTestJob
  end

  it "adds failure to the class" do
    expect(under_test).to respond_to :failure
  end

  it "logs the error and schedules a job on failure" do
    dummy_job = double("job")
    allow(dummy_job).to receive(:id)
    expect(dummy_job).to receive(:update_attributes!)
    expect(ScheduledJob.logger).to receive(:error)
    expect(UnderTest).to receive(:schedule_job)
    allow(Delayed::Job).to receive(:enqueue)
    under_test.failure(dummy_job)
  end

  it "adds error to the class" do
    expect(under_test).to respond_to :error
  end

  it "logs on error" do
    job = double("job")
    allow(job).to receive(:id) { 4 }
    expect(ScheduledJob.logger).to receive(:warn)
    allow(UnderTest).to receive(:schedule_job)
    under_test.error job, nil
  end

  it "wraps delayed job with scheduled_job" do
    job = double("job")
    allow(job).to receive(:id) { 4 }
    instance = double("instance")
    allow(UnderTest).to receive(:new) { instance }
    expect(Delayed::Job).to receive(:where).and_return([])
    expect(Delayed::Job).to receive(:enqueue).with(instance, run_at: "time to recur", queue: "TESTING")
    UnderTest.schedule_job job
  end

  it 'doesnt find substring jobs as existing' do
    UnderTest.schedule_job
    Test.schedule_job
    expect(Delayed::Job.count).to eq(2)
  end

  it "scheduled a job even if there is total failure and an existing job" do
    dummy_job = double("job")
    allow(dummy_job).to receive(:id)
    expect(dummy_job).to receive(:update_attributes!)
    expect(Delayed::Job).to receive(:where).twice.and_return([])
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
