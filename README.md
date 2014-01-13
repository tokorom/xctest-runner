xctest-runner
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

xctest-runner may be able to find the appropriate Target automatically.

### If you would like to run a specific test case

```shell
$ xctest-runner -test SampleTests/testSample
```

### If you specify a target

```shell
$ xctest-runner -target YourTestsTarget
```

### If you specify a scheme

```shell
$ xctest-runner -scheme YourScheme
```

### If you specify a workspace

```shell
$ xctest-runner -workspace Sample.xcworkspace
```

### If you specify a project

```shell
$ xctest-runner -project Sample.xcodeproj
```

## Advanced Usage

### If you would like to use [xcpretty](https://github.com/mneorr/XCPretty)

```shell
$ xctest-runner 2>&1 | xcpretty -c
```

### If you would like add your build options

```shell
$ xctest-runner -suffix "OBJROOT=."
```

## Copyright

Copyright (c) 2014 tokorom. See LICENSE.txt for
further details.

