require 'test_helper'
require 'lotus/utils/callbacks'

class Callable
  def call
  end
end

class Action
  attr_reader :logger

  def initialize
    @logger = Array.new
  end

  private
  def authenticate!
    logger.push 'authenticate!'
  end

  def set_article(params)
    logger.push "set_article: #{ params[:id] }"
  end
end

describe Lotus::Utils::Callbacks::Chain do
  before do
    @chain = Lotus::Utils::Callbacks::Chain.new
  end

  describe '#add' do
    it 'wraps the given callback with a callable object' do
      @chain.add :symbolize!

      cb = @chain.first
      cb.must_respond_to(:call)
    end

    describe 'when a callable object is passed' do
      before do
        @chain.add callback
      end

      let(:callback) { Callable.new }

      it 'includes the given callback' do
        cb = @chain.first
        cb.callback.must_equal(callback)
      end
    end

    describe 'when a Symbol is passed' do
      before do
        @chain.add callback
      end

      let(:callback) { :upcase }

      it 'includes the given callback' do
        cb = @chain.first
        cb.callback.must_equal(callback)
      end

      it 'guarantees unique entries' do
        # add the callback again, see before block
        @chain.add callback
        @chain.size.must_equal(1)
      end
    end

    describe 'when a block is passed' do
      before do
        @chain.add(&callback)
      end

      let(:callback) { Proc.new{} }

      it 'includes the given callback' do
        cb = @chain.first
        assert_equal cb.callback, callback
      end
    end

    describe 'when multiple callbacks are passed' do
      before do
        @chain.add *callbacks
      end

      let(:callbacks) { [:upcase, Callable.new, Proc.new{}] }

      it 'includes all the given callbacks' do
        @chain.size.must_equal(callbacks.size)
      end

      it 'all the included callbacks are callable' do
        @chain.each do |callback|
          callback.must_respond_to(:call)
        end
      end
    end
  end

  describe '#run' do
    let(:action) { Action.new }
    let(:params) { Hash[id: 23] }

    describe 'when symbols are passed' do
      before do
        @chain.add :authenticate!, :set_article
        @chain.run action, params
      end

      it 'executes the callbacks' do
        authenticate = action.logger.shift
        authenticate.must_equal 'authenticate!'

        set_article = action.logger.shift
        set_article.must_equal "set_article: #{ params[:id] }"
      end
    end

    describe 'when procs are passed' do
      before do
        @chain.add do
          logger.push 'authenticate!'
        end

        @chain.add do |params|
          logger.push "set_article: #{ params[:id] }"
        end

        @chain.run action, params
      end

      it 'executes the callbacks' do
        authenticate = action.logger.shift
        authenticate.must_equal 'authenticate!'

        set_article = action.logger.shift
        set_article.must_equal "set_article: #{ params[:id] }"
      end
    end

  end
end

# describe Lotus::Utils::Callbacks::Callback do
# end

# describe Lotus::Utils::Callbacks::MethodCallback do
# end