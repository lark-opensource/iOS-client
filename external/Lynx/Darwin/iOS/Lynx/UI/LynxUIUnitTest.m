//  Copyright 2023 The Lynx Authors. All rights reserved.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "LynxUI+Internal.h"

@implementation LynxUI (Test)
- (UIView*)createView {
  return nil;
}
@end

@interface LynxUIUnitTest : XCTestCase
@end
@implementation LynxUIUnitTest

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each test method in the
  // class.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the
  // class.
}

- (void)testIsVisible {
  LynxUI* ui = OCMPartialMock([[LynxUI alloc] initWithView:nil]);
  XCTAssertFalse([ui isVisible]);

  UIView* view = OCMClassMock([UIView class]);
  CGRect rect = CGRectZero;
  ui = OCMPartialMock([[LynxUI alloc] initWithView:view]);
  OCMExpect([view isHidden]).andReturn(NO);
  OCMExpect([view alpha]).andReturn(1);
  OCMExpect([view frame]).andReturn(rect);
  OCMExpect([view clipsToBounds]).andReturn(NO);
  OCMExpect([view window]).andReturn(OCMClassMock([UIWindow class]));

  XCTAssertTrue([ui isVisible]);
  OCMVerifyAll(ui);
}

@end
