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
                Tests
      EOS
    }
  end

  context 'Defaults' do
    it 'runs xcodebuild with default options' do
      expect(opts.count).to eq 3
      expect(opts['-sdk']).to eq 'iphonesimulator'
      expect(opts['-configuration']).to eq 'Debug'
      expect(opts['-scheme']).to eq 'Tests'
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

    describe 'ENV' do
      it 'contains environments' do
        env = runner.current_environment('xcodebuild -showBuildSettings test')
        expect(env['SDKROOT']).to_not eq 'xxx'
        expect(env['SDK_DIR']).to eq '/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator7.0.sdk'
        expect(env['EXECUTABLE_FOLDER_PATH']).to eq 'Tests.xctest'
        expect(env['EXECUTABLE_PATH']).to eq 'Tests.xctest/Tests'
      end
    end

    describe 'test command' do
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

    describe 'SchemeManager' do
      context 'without scheme' do
        it 'does not call write_xml' do
          expect(runner).to_not receive(:write_xml)
          runner.run
        end
      end

      context 'with scheme' do
        let(:arguments) {
          {:scheme => 'Tests'}
        }
        let (:temp_xml) {
          double('xml')
        }

        before(:each) do
          Find.stub(:find).and_yield('./Tests.xcscheme')
          File.stub(:open).and_return(xcscheme_xml)
        end

        context 'need to be updated' do
          let(:xcscheme_xml) {
            StringIO.new <<EOS
  <?xml version="1.0" encoding="UTF-8"?>
  <Scheme
     LastUpgradeVersion = "0500"
     version = "1.3">
     <BuildAction
        parallelizeBuildables = "YES"
        buildImplicitDependencies = "YES">
        <BuildActionEntries>
           <BuildActionEntry
              buildForTesting = "YES"
              buildForRunning = "YES"
              buildForProfiling = "YES"
              buildForArchiving = "YES"
              buildForAnalyzing = "YES">
              <BuildableReference
                 BuildableIdentifier = "primary"
                 BlueprintIdentifier = "06D7A7C2188AC90900D09064"
                 BuildableName = "CocoaPodsProjectSample.app"
                 BlueprintName = "CocoaPodsProjectSample"
                 ReferencedContainer = "container:CocoaPodsProjectSample.xcodeproj">
              </BuildableReference>
           </BuildActionEntry>
           <BuildActionEntry
              buildForTesting = "YES"
              buildForRunning = "NO"
              buildForProfiling = "NO"
              buildForArchiving = "NO"
              buildForAnalyzing = "NO">
              <BuildableReference
                 BuildableIdentifier = "primary"
                 BlueprintIdentifier = "06D7A7E6188AC90900D09064"
                 BuildableName = "CocoaPodsProjectSampleTests.xctest"
                 BlueprintName = "CocoaPodsProjectSampleTests"
                 ReferencedContainer = "container:CocoaPodsProjectSample.xcodeproj">
              </BuildableReference>
           </BuildActionEntry>
        </BuildActionEntries>
     </BuildAction>
     <TestAction
        selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
        selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
        shouldUseLaunchSchemeArgsEnv = "YES"
        buildConfiguration = "Debug">
        <Testables>
           <TestableReference
              skipped = "NO">
              <BuildableReference
                 BuildableIdentifier = "primary"
                 BlueprintIdentifier = "06D7A7E6188AC90900D09064"
                 BuildableName = "CocoaPodsProjectSampleTests.xctest"
                 BlueprintName = "CocoaPodsProjectSampleTests"
                 ReferencedContainer = "container:CocoaPodsProjectSample.xcodeproj">
              </BuildableReference>
           </TestableReference>
        </Testables>
        <MacroExpansion>
           <BuildableReference
              BuildableIdentifier = "primary"
              BlueprintIdentifier = "06D7A7C2188AC90900D09064"
              BuildableName = "CocoaPodsProjectSample.app"
              BlueprintName = "CocoaPodsProjectSample"
              ReferencedContainer = "container:CocoaPodsProjectSample.xcodeproj">
           </BuildableReference>
        </MacroExpansion>
     </TestAction>
     <LaunchAction
        selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
        selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
        launchStyle = "0"
        useCustomWorkingDirectory = "NO"
        buildConfiguration = "Debug"
        ignoresPersistentStateOnLaunch = "NO"
        debugDocumentVersioning = "YES"
        allowLocationSimulation = "YES">
        <BuildableProductRunnable>
           <BuildableReference
              BuildableIdentifier = "primary"
              BlueprintIdentifier = "06D7A7C2188AC90900D09064"
              BuildableName = "CocoaPodsProjectSample.app"
              BlueprintName = "CocoaPodsProjectSample"
              ReferencedContainer = "container:CocoaPodsProjectSample.xcodeproj">
           </BuildableReference>
        </BuildableProductRunnable>
        <AdditionalOptions>
        </AdditionalOptions>
     </LaunchAction>
     <ProfileAction
        shouldUseLaunchSchemeArgsEnv = "YES"
        savedToolIdentifier = ""
        useCustomWorkingDirectory = "NO"
        buildConfiguration = "Release"
        debugDocumentVersioning = "YES">
        <BuildableProductRunnable>
           <BuildableReference
              BuildableIdentifier = "primary"
              BlueprintIdentifier = "06D7A7C2188AC90900D09064"
              BuildableName = "CocoaPodsProjectSample.app"
              BlueprintName = "CocoaPodsProjectSample"
              ReferencedContainer = "container:CocoaPodsProjectSample.xcodeproj">
           </BuildableReference>
        </BuildableProductRunnable>
     </ProfileAction>
     <AnalyzeAction
        buildConfiguration = "Debug">
     </AnalyzeAction>
     <ArchiveAction
        buildConfiguration = "Release"
        revealArchiveInOrganizer = "YES">
     </ArchiveAction>
  </Scheme>
EOS
          }

          describe 'write and unlink' do
            it 'is called' do
              expect(File).to receive(:open).with(anything(), 'w').and_return(double('file'))
              expect(File).to receive(:unlink)
              runner.run
            end
          end

          it 'write temp scheme' do
            expect(File).to receive(:open).with('./XCTestRunnerTemp.xcscheme', 'w').and_yield(temp_xml)
            expect(File).to receive(:unlink)
            expect(temp_xml).to receive(:sync=).with(true)
            temp_xml.stub(:write) do |xml|
              entry = xml.get_elements('Scheme/BuildAction/BuildActionEntries/BuildActionEntry').first
              expect(entry).to_not be_nil
              expect(entry.attributes['buildForTesting']).to eq('YES')
              expect(entry.attributes['buildForRunning']).to eq('YES')
            end
            runner.run
          end
        end

        context 'need not to be updated' do
          let(:xcscheme_xml) {
            StringIO.new <<EOS
  <?xml version="1.0" encoding="UTF-8"?>
  <Scheme
     LastUpgradeVersion = "0500"
     version = "1.3">
     <BuildAction
        parallelizeBuildables = "YES"
        buildImplicitDependencies = "YES">
        <BuildActionEntries>
           <BuildActionEntry
              buildForTesting = "YES"
              buildForRunning = "YES"
              buildForProfiling = "YES"
              buildForArchiving = "YES"
              buildForAnalyzing = "YES">
              <BuildableReference
                 BuildableIdentifier = "primary"
                 BlueprintIdentifier = "06D7A7C2188AC90900D09064"
                 BuildableName = "CocoaPodsProjectSample.app"
                 BlueprintName = "CocoaPodsProjectSample"
                 ReferencedContainer = "container:CocoaPodsProjectSample.xcodeproj">
              </BuildableReference>
           </BuildActionEntry>
           <BuildActionEntry
              buildForTesting = "YES"
              buildForRunning = "YES"
              buildForProfiling = "NO"
              buildForArchiving = "NO"
              buildForAnalyzing = "NO">
              <BuildableReference
                 BuildableIdentifier = "primary"
                 BlueprintIdentifier = "06D7A7E6188AC90900D09064"
                 BuildableName = "CocoaPodsProjectSampleTests.xctest"
                 BlueprintName = "CocoaPodsProjectSampleTests"
                 ReferencedContainer = "container:CocoaPodsProjectSample.xcodeproj">
              </BuildableReference>
           </BuildActionEntry>
        </BuildActionEntries>
     </BuildAction>
     <TestAction
        selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
        selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
        shouldUseLaunchSchemeArgsEnv = "YES"
        buildConfiguration = "Debug">
        <Testables>
           <TestableReference
              skipped = "NO">
              <BuildableReference
                 BuildableIdentifier = "primary"
                 BlueprintIdentifier = "06D7A7E6188AC90900D09064"
                 BuildableName = "CocoaPodsProjectSampleTests.xctest"
                 BlueprintName = "CocoaPodsProjectSampleTests"
                 ReferencedContainer = "container:CocoaPodsProjectSample.xcodeproj">
              </BuildableReference>
           </TestableReference>
        </Testables>
        <MacroExpansion>
           <BuildableReference
              BuildableIdentifier = "primary"
              BlueprintIdentifier = "06D7A7C2188AC90900D09064"
              BuildableName = "CocoaPodsProjectSample.app"
              BlueprintName = "CocoaPodsProjectSample"
              ReferencedContainer = "container:CocoaPodsProjectSample.xcodeproj">
           </BuildableReference>
        </MacroExpansion>
     </TestAction>
     <LaunchAction
        selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
        selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
        launchStyle = "0"
        useCustomWorkingDirectory = "NO"
        buildConfiguration = "Debug"
        ignoresPersistentStateOnLaunch = "NO"
        debugDocumentVersioning = "YES"
        allowLocationSimulation = "YES">
        <BuildableProductRunnable>
           <BuildableReference
              BuildableIdentifier = "primary"
              BlueprintIdentifier = "06D7A7C2188AC90900D09064"
              BuildableName = "CocoaPodsProjectSample.app"
              BlueprintName = "CocoaPodsProjectSample"
              ReferencedContainer = "container:CocoaPodsProjectSample.xcodeproj">
           </BuildableReference>
        </BuildableProductRunnable>
        <AdditionalOptions>
        </AdditionalOptions>
     </LaunchAction>
     <ProfileAction
        shouldUseLaunchSchemeArgsEnv = "YES"
        savedToolIdentifier = ""
        useCustomWorkingDirectory = "NO"
        buildConfiguration = "Release"
        debugDocumentVersioning = "YES">
        <BuildableProductRunnable>
           <BuildableReference
              BuildableIdentifier = "primary"
              BlueprintIdentifier = "06D7A7C2188AC90900D09064"
              BuildableName = "CocoaPodsProjectSample.app"
              BlueprintName = "CocoaPodsProjectSample"
              ReferencedContainer = "container:CocoaPodsProjectSample.xcodeproj">
           </BuildableReference>
        </BuildableProductRunnable>
     </ProfileAction>
     <AnalyzeAction
        buildConfiguration = "Debug">
     </AnalyzeAction>
     <ArchiveAction
        buildConfiguration = "Release"
        revealArchiveInOrganizer = "YES">
     </ArchiveAction>
  </Scheme>
EOS
          }

          describe 'write and unlink' do
            it 'is not called' do
              expect(File).to_not receive(:open).with(anything(), 'w')
              expect(File).to_not receive(:unlink)
              runner.run
            end
          end
        end

        context 'build action entries is not exist' do
          let(:xcscheme_xml) {
            StringIO.new <<EOS
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "0500"
   version = "1.3">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
   </BuildAction>
   <TestAction
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      buildConfiguration = "Debug">
      <Testables>
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "xxxxxxx"
               BuildableName = "Tests.xctest"
               BlueprintName = "Tests"
               ReferencedContainer = "container:XXX.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      buildConfiguration = "Debug"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      allowLocationSimulation = "YES">
      <AdditionalOptions>
      </AdditionalOptions>
   </LaunchAction>
   <ProfileAction
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      buildConfiguration = "Debug"
      debugDocumentVersioning = "YES">
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Debug"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
EOS
          }

          describe 'write and unlink' do
            it 'is called' do
              expect(File).to receive(:open).with(anything(), 'w')
              expect(File).to receive(:unlink)
              runner.run
            end
          end

          it 'write temp scheme' do
            expect(File).to receive(:open).with('./XCTestRunnerTemp.xcscheme', 'w').and_yield(temp_xml)
            expect(File).to receive(:unlink)
            expect(temp_xml).to receive(:sync=).with(true)
            temp_xml.stub(:write) do |xml|
              entry = xml.get_elements('Scheme/BuildAction/BuildActionEntries/BuildActionEntry').first
              expect(entry).to_not be_nil
              expect(entry.attributes['buildForTesting']).to eq('YES')
              expect(entry.attributes['buildForRunning']).to eq('YES')
            end
            runner.run
          end
        end

      end
    end
  end

end
