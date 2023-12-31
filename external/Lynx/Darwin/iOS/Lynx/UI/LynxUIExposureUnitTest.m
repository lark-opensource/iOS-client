//  Copyright 2023 The Lynx Authors. All rights reserved.

#import "LynxUIExposureUnitTest.h"
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

@interface LynxUIExposureUnitTest : XCTestCase {
  LynxUIExposure* exposure;
}
@end
@implementation LynxUIExposureUnitTest

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each test method in the
  // class.
  exposure = [[LynxUIExposure alloc] init];
  // will call real method if not stubbed
  exposure = OCMPartialMock(exposure);
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the
  // class.
  exposure = NULL;
}

- (void)testStopExposure {
  NSMutableSet<LynxUIExposureDetail*>* set = OCMClassMock([NSMutableSet class]);
  exposure.uiInWindowMapBefore = set;
  OCMExpect([exposure removeFromRunLoop]);
  OCMExpect([exposure sendEvent:[OCMArg any] eventName:@"disexposure"]);
  OCMExpect([set removeAllObjects]);
  [exposure stopExposure];
  OCMVerifyAll(exposure);
  OCMVerifyAll(set);
}

@end
