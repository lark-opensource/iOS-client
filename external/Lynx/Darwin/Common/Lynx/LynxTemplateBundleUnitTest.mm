//  Copyright 2022 The Lynx Authors. All rights reserved.

#import <XCTest/XCTest.h>
#import "LynxTemplateBundle.h"
#include "tasm/config.h"

@interface LynxTemplateBundleUnitTest : XCTestCase

@end

@implementation LynxTemplateBundleUnitTest

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each test method in the
  // class.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the
  // class.
}

- (void)testTemplateBundleLepus {
  // This is an example of a functional test case.
  // Use XCTAssert and related functions to verify your tests produce the correct results.
  lynx::tasm::Config::Initialize(0, 0, 1, "");
  NSBundle* bundle = [NSBundle bundleForClass:[self class]];
  NSString* str = @"TestResource.bundle/use-lepus.js";
  NSString* url = [bundle pathForResource:[str stringByDeletingPathExtension] ofType:@"js"];
  LynxTemplateBundle* template_bundle =
      [[LynxTemplateBundle alloc] initWithTemplate:[NSData dataWithContentsOfFile:url]];
  XCTAssertEqual(template_bundle.errorMsg, nil);
}

- (void)testTemplateBundleLepusNG {
  // This is an example of a functional test case.
  // Use XCTAssert and related functions to verify your tests produce the correct results.
  lynx::tasm::Config::Initialize(0, 0, 1, "");
  NSBundle* bundle = [NSBundle bundleForClass:[self class]];
  NSString* str = @"TestResource.bundle/use-lepusng.js";
  NSString* url = [bundle pathForResource:[str stringByDeletingPathExtension] ofType:@"js"];
  LynxTemplateBundle* template_bundle =
      [[LynxTemplateBundle alloc] initWithTemplate:[NSData dataWithContentsOfFile:url]];
  XCTAssertEqual(template_bundle.errorMsg, nil);
}

- (void)testGetExtraInfo {
  // This is an example of a functional test case.
  // Use XCTAssert and related functions to verify your tests produce the correct results.
  lynx::tasm::Config::Initialize(0, 0, 1, "");
  NSBundle* bundle = [NSBundle bundleForClass:[self class]];
  NSString* str = @"TestResource.bundle/extra-info.js";
  NSString* url = [bundle pathForResource:[str stringByDeletingPathExtension] ofType:@"js"];
  LynxTemplateBundle* template_bundle =
      [[LynxTemplateBundle alloc] initWithTemplate:[NSData dataWithContentsOfFile:url]];
  NSDictionary* extraInfo = [template_bundle extraInfo];
  XCTAssertEqual(template_bundle.errorMsg, nil);
  XCTAssertEqualObjects([extraInfo objectForKey:@"a"], @1);
}

@end
