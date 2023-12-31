//  Copyright © 2022 Lynx. All rights reserved.

#import <XCTest/XCTest.h>
#import "LynxHtmlEscape.h"

@interface LynxHtmlEscapeUnitTest : XCTestCase

@end

@implementation LynxHtmlEscapeUnitTest

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each test method in the
  // class.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the
  // class.
}

- (void)testStringByUnescapingFromHtml {
  XCTAssertEqualObjects([@"x &gt; 10" stringByUnescapingFromHtml], @"x > 10");
  XCTAssertEqualObjects([@"<h1>Pride &amp; Prejudice</h1>" stringByUnescapingFromHtml],
                        @"<h1>Pride & Prejudice</h1>");
}

@end
