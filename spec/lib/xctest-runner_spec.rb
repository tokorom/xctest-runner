require 'xctest-runner'

describe XCTestRunner do

  let(:arguments) {
    {}
  }

  let(:runner) {
    XCTestRunner.new(arguments)
  }

  let(:opts) {
    option = runner.build_option
    opts = {}
    option.scan(/(-\w+) (\w+)/) do |opt, value|
      opts[opt] = value
    end
    opts
  }

  before(:each) do
    XCTestRunner.any_instance.stub(:execute_command) {
      true
    }
    XCTestRunner.any_instance.stub(:execute_command).with(/\s-showBuildSettings/) {
      <<-EOS
        Build settings from command line:
            SDKROOT = iphonesimulator7.0

        Build settings for action test and target Tests:
            HOGE = "huga"
      EOS
    }
    XCTestRunner.any_instance.stub(:execute_command).with(/\s-list/) {
      <<-EOS
        Information about project "PodSample":
            Targets:
                PodSample
                PodSampleTests

            Build Configurations:
                Debug
                Release

            If no build configuration is specified and -scheme is not passed then "Release" is used.

            Schemes:
                PodSample
      EOS
    }
  end

  context 'Defaults' do
    it 'runs xcodebuild with default options' do
      expect(opts.count).to eq 3
      expect(opts['-sdk']).to eq 'iphonesimulator'
      expect(opts['-configuration']).to eq 'Debug'
      expect(opts['-target']).to eq 'PodSampleTests'
    end

    it 'doese not run clean command' do
      expect(runner).to_not receive(:clean)
      expect(runner).to receive(:build).and_return(true)
      expect(runner).to receive(:test).with('Self')
      runner.run
    end
  end

  context '-scheme option' do
    let(:arguments) {
      {:scheme => 'Tests'}
    }

    it 'has some build arguments' do
      expect(opts.count).to eq 3
      expect(opts['-scheme']).to eq 'Tests'
    end
  end

  context '-workspace option' do
    let(:arguments) {
      {:workspace => 'Sample'}
    }

    it 'has some build arguments' do
      expect(opts.count).to eq 4
      expect(opts['-workspace']).to eq 'Sample'
    end
  end

  context '-project option' do
    let(:arguments) {
      {:project => 'Sample'}
    }

    it 'has some build arguments' do
      expect(opts.count).to eq 4
      expect(opts['-project']).to eq 'Sample'
    end
  end

  context '-target option' do
    let(:arguments) {
      {:target => 'Tests'}
    }

    it 'has some build arguments' do
      expect(opts.count).to eq 3
      expect(opts['-target']).to eq 'Tests'
    end
  end

  context '-sdk option' do
    let(:arguments) {
      {:sdk => 'iphoneos'}
    }

    it 'has some build arguments' do
      expect(opts.count).to eq 3
      expect(opts['-sdk']).to eq 'iphoneos'
    end
  end

  context '-arch option' do
    let(:arguments) {
      {:arch => 'i386'}
    }

    it 'has some build arguments' do
      expect(opts.count).to eq 4
      expect(opts['-arch']).to eq 'i386'
    end
  end

  context '-configuration option' do
    let(:arguments) {
      {:configuration => 'Release'}
    }

    it 'has some build arguments' do
      expect(opts.count).to eq 3
      expect(opts['-configuration']).to eq 'Release'
    end
  end

  context '-test option' do
    let(:arguments) {
      {:test => 'SampleTests/testCase'}
    }

    it 'has some build arguments' do
      expect(opts.count).to eq 3
    end

    it 'run test command with the specific test case' do
      expect(runner).to receive(:execute_command).with(/\s-XCTest SampleTests\/testCase/, true)
      runner.run
    end
  end

  context '-clean option' do
    let(:arguments) {
      {:clean => true}
    }

    it 'has some build arguments' do
      expect(opts.count).to eq 3
    end

    it 'run clean command' do
      expect(runner).to receive(:clean)
      expect(runner).to receive(:build).and_return(true)
      expect(runner).to receive(:test).with('Self')
      runner.run
    end

    it 'would not run test command if build returns false' do
      expect(runner).to receive(:clean)
      expect(runner).to receive(:build).and_return(false)
      expect(runner).to_not receive(:test).with('Self')
      runner.run
    end
  end

  context '-suffix option' do
    let(:arguments) {
      {:suffix => 'OBJROOT=.'}
    }

    it 'has some build arguments' do
      expect(opts.count).to eq 3
    end

    it 'run test command with the suffix' do
      expect(runner).to receive(:execute_command).with(/\sOBJROOT=\./, true)
      runner.build
      expect(runner).to receive(:execute_command).with(/\sOBJROOT=\./, true)
      runner.test
    end
  end

  context 'Build environment' do
    before(:each) do
      XCTestRunner.any_instance.stub(:execute_command).with(/\s-showBuildSettings/) {
        <<-EOS
          Build settings from command line:
              SDKROOT = iphonesimulator7.0

          Build settings for action test and target Demo:
              SDKROOT = xxx
              SDK_DIR = xxx
              BUILT_PRODUCTS_DIR = xxx
              FULL_PRODUCT_NAME = Demo.app
              EXECUTABLE_FOLDER_PATH = Demo.app
              EXECUTABLE_PATH = Demo.app/Demo

          Build settings for action test and target Tests:
              SDKROOT = /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator7.0.sdk
              SDK_DIR = /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator7.0.sdk
              BUILT_PRODUCTS_DIR = /Users/xxx/Library/Developer/Xcode/DerivedData/XCTestRunner-xxx/Build/Products/Debug-iphonesimulator
              FULL_PRODUCT_NAME = Tests.xctest
              EXECUTABLE_FOLDER_PATH = Tests.xctest
              EXECUTABLE_PATH = Tests.xctest/Tests

        EOS
      }
    end

    context 'ENV' do
      it 'contains environments' do
        env = runner.current_environment('xcodebuild -showBuildSettings test')
        expect(env['SDKROOT']).to_not eq 'xxx'
        expect(env['SDK_DIR']).to eq '/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator7.0.sdk'
        expect(env['EXECUTABLE_FOLDER_PATH']).to eq 'Tests.xctest'
        expect(env['EXECUTABLE_PATH']).to eq 'Tests.xctest/Tests'
      end
    end

    context 'test command' do
      it 'contains xctest command' do
        expect(runner.test_command('Self')).to include '/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator7.0.sdk/Developer/usr/bin/xctest '
      end

      it 'contains test bundle' do
        expect(runner.test_command('Self')).to include ' /Users/xxx/Library/Developer/Xcode/DerivedData/XCTestRunner-xxx/Build/Products/Debug-iphonesimulator/Tests.xctest'
      end

      it 'contains arch DYLD_ROOT_PATH' do
        expect(runner.test_command('Self')).to include "-e DYLD_ROOT_PATH='/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator7.0.sdk'"
      end

      it 'contains arch command' do
        expect(runner.test_command('Self')).to include 'arch -arch i386 '
      end
    end
  end

end
