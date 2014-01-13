require 'xctest-runner'

describe XCTestRunner do
  class XCTestRunner
    attr_accessor :last_command

    def execute_command(command, need_puts = false)
      @last_command = command
      if command.include?('-showBuildSettings')
        build_settings
      end
    end

    def build_settings
      <<-EOS
        Build settings from command line:
            SDKROOT = iphonesimulator7.0

        Build settings for action test and target Tests:
            HOGE = "huga"
      EOS
    end
  end

  let(:opts) {
    option = @runner.xcodebuild_option
    opts = {}
    option.scan(/(-\w+) (\w+)/) do |opt, value|
      opts[opt] = value
    end
    opts
  }

  context 'Defaults' do
    before(:each) do
      @runner = XCTestRunner.new
    end

    it 'runs xcodebuild with default options' do
      expect(opts.count).to eq 3
      expect(opts['-sdk']).to eq 'iphonesimulator'
      expect(opts['-arch']).to eq 'x86_64'
      expect(opts['-configuration']).to eq 'Debug'
    end

    it 'doese not run clean command' do
      @runner.should_not_receive(:clean)
      @runner.should_receive(:build)
      @runner.should_receive(:test).with('Self')
      @runner.run
    end
  end

  context '-scheme option' do
    before(:each) do
      @runner = XCTestRunner.new({:scheme => 'Tests'})
    end

    it 'has some build arguments' do
      expect(opts.count).to eq 4
      expect(opts['-scheme']).to eq 'Tests'
    end
  end

  context '-workspace option' do
    before(:each) do
      @runner = XCTestRunner.new({:workspace => 'Sample'})
    end

    it 'has some build arguments' do
      expect(opts.count).to eq 4
      expect(opts['-workspace']).to eq 'Sample'
    end
  end

  context '-project option' do
    before(:each) do
      @runner = XCTestRunner.new({:project => 'Sample'})
    end

    it 'has some build arguments' do
      expect(opts.count).to eq 4
      expect(opts['-project']).to eq 'Sample'
    end
  end

  context '-target option' do
    before(:each) do
      @runner = XCTestRunner.new({:target => 'Tests'})
    end

    it 'has some build arguments' do
      expect(opts.count).to eq 4
      expect(opts['-target']).to eq 'Tests'
    end
  end

  context '-sdk option' do
    before(:each) do
      @runner = XCTestRunner.new({:sdk => 'iphoneos'})
    end

    it 'has some build arguments' do
      expect(opts.count).to eq 3
      expect(opts['-sdk']).to eq 'iphoneos'
    end
  end

  context '-arch option' do
    before(:each) do
      @runner = XCTestRunner.new({:arch => 'armv7'})
    end

    it 'has some build arguments' do
      expect(opts.count).to eq 3
      expect(opts['-arch']).to eq 'armv7'
    end
  end

  context '-configuration option' do
    before(:each) do
      @runner = XCTestRunner.new({:configuration => 'Release'})
    end

    it 'has some build arguments' do
      expect(opts.count).to eq 3
      expect(opts['-configuration']).to eq 'Release'
    end
  end

  context '-test option' do
    before(:each) do
      @runner = XCTestRunner.new({:test => 'SampleTests/testCase'})
    end

    it 'has some build arguments' do
      expect(opts.count).to eq 3
    end

    it 'run test command with the specific test case' do
      @runner.run
      expect(@runner.last_command).to include '-XCTest SampleTests/testCase'
    end
  end

  context '-clean option' do
    before(:each) do
      @runner = XCTestRunner.new({:clean => true})
    end

    it 'has some build arguments' do
      expect(opts.count).to eq 3
    end

    it 'run clean command' do
      @runner.should_receive(:clean)
      @runner.should_receive(:build)
      @runner.should_receive(:test).with('Self')
      @runner.run
    end
  end

  context '-suffix option' do
    before(:each) do
      @runner = XCTestRunner.new({:suffix => 'OBJROOT=.'})
    end

    it 'has some build arguments' do
      expect(opts.count).to eq 3
    end

    it 'run test command with the suffix' do
      @runner.build
      expect(@runner.last_command).to include ' OBJROOT=.'
      @runner.test
      expect(@runner.last_command).to include ' OBJROOT=.'
    end
  end

  context 'Build environment' do
    class XCTestRunner
      def build_settings
        <<-EOS
          Build settings from command line:
              SDKROOT = iphonesimulator7.0

          Build settings for action test and target Tests:
              SDKROOT = /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator7.0.sdk
              SDK_DIR = /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator7.0.sdk
              BUILT_PRODUCTS_DIR = /Users/tokorom/Library/Developer/Xcode/DerivedData/XCTestRunner-xxx/Build/Products/Debug-iphonesimulator
              FULL_PRODUCT_NAME = Tests.xctest

          Build settings for action test and target Demo:
              SDKROOT = xxx
              SDK_DIR = xxx
              BUILT_PRODUCTS_DIR = xxx
              FULL_PRODUCT_NAME = Demo.app
        EOS
      end
    end

    before(:each) do
      @runner = XCTestRunner.new
    end

    context 'ENV' do
      it 'contains DYLD_ROOT_PATH' do
        @runner.configure_environment('xcodebuild -showBuildSettings test')
        expect(ENV['SDKROOT']).to_not eq 'xxx'
        expect(ENV['DYLD_ROOT_PATH']).to eq ENV['SDK_DIR']
      end
    end

    context 'test command' do
      it 'contains xctest command' do
        expect(@runner.test_command('Self')).to include '/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator7.0.sdk/Developer/usr/bin/xctest '
      end

      it 'contains test bundle' do
        expect(@runner.test_command('Self')).to include ' /Users/tokorom/Library/Developer/Xcode/DerivedData/XCTestRunner-xxx/Build/Products/Debug-iphonesimulator/Tests.xctest'
      end
    end
  end
end
