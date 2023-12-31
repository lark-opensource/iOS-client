//
//  TestInjectJS.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/19.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RangersAppLog/BDAutoTrackWebViewTrackJS.h>

@interface TestInjectJS : XCTestCase

@end

@implementation TestInjectJS

- (void)testTrackJS {
    NSString *js1 = bd_ui_trackJS();
    NSString *js2 = bd_ui_trackJS();
    XCTAssertNotNil(js1);
    XCTAssertEqualObjects(js1, js2);
}


@end
