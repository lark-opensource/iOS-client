// Copyright 2023 The Lynx Authors. All rights reserved.

#import "resource_loader_darwin.h"
#import <XCTest/XCTest.h>

@interface ResourceLoaderDarwinUnitTest : XCTestCase {
  lynx::piper::JSSourceLoaderDarwin* _loader;
}

@end

@implementation ResourceLoaderDarwinUnitTest

- (void)setUp {
  _loader = new lynx::piper::JSSourceLoaderDarwin();
}

- (void)testLoadLynxJSAsset {
  NSBundle* frameworkBundle = [NSBundle bundleForClass:[self class]];
  NSURL* bundleUrl = [frameworkBundle URLForResource:@"TestResource" withExtension:@"bundle"];
  NSURL* devBundleUrl = [frameworkBundle URLForResource:@"TestDebugResource"
                                          withExtension:@"bundle"];
  // file exists
  std::string resource1 =
      _loader->LoadLynxJSAsset("lynx_assets://lynx_canvas.js", *bundleUrl, *devBundleUrl);
  XCTAssertGreaterThan(resource1.length(), 0ul);
  // file does not exist
  std::string resource2 =
      _loader->LoadLynxJSAsset("lynx_assets://non-exist.js", *bundleUrl, *devBundleUrl);
  XCTAssertEqual(resource2.length(), 0ul);
}

@end
