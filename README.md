xctest-runner [![Gem Version](https://badge.fury.io/rb/xctest-runner.png)](http://badge.fury.io/rb/xctest-runner) [![build](https://travis-ci.org/tokorom/xctest-runner.png?branch=master)](https://travis-ci.org/tokorom/xctest-runner)
===================

The unit tests runner for xctest.  
You can run only a specific test case in the CUI!

## Installation

```shell
$ gem install xctest-runner
```

## Usage

### Simple usage

```shell
$ xctest-runner
```

xctest-runner may be able to find the appropriate Scheme automatically.

### If you would like to run a specific test case

```shell
$ xctest-runner -test SampleTests/testSample
```

### If you specify a scheme

```shell
$ xctest-runner -scheme YourScheme
```

### If you specify a project

```shell
$ xctest-runner -project Sample.xcodeproj
```

### If you specify a workspace

```shell
$ xctest-runner -workspace Sample.xcworkspace
```

## Advanced Usage

### If you would like to use [CocoaPods](http://cocoapods.org/)

```shell
$ xctest-runner -workspace YourCocoaPods.xcworkspace -scheme YourProjectScheme
```

### If you would like to use [xcpretty](https://github.com/mneorr/XCPretty)

```shell
$ xctest-runner 2>&1 | xcpretty -c
```

### If you would like add your build options

```shell
$ xctest-runner -suffix "OBJROOT=."
```

## License

MIT

## Copyright

Copyright (c) 2014 tokorom.

