//
//  TestBDKeyWindow.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/19.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RangersAppLog/BDKeyWindowTracker.h>

@interface TestBDKeyWindow : XCTestCase

@end

@implementation TestBDKeyWindow

- (void)testKeyWindow {
    UIWindow *window = [UIWindow new];
    [BDKeyWindowTracker sharedInstance].keyWindow = window;
    XCTAssertEqualObjects(window, [BDKeyWindowTracker sharedInstance].keyWindow);
    [BDKeyWindowTracker sharedInstance].keyWindow = nil;
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    XCTAssertEqualObjects([BDKeyWindowTracker sharedInstance].keyWindow,keyWindow);
}

- (void)testSceneKeyWindow {
    UIWindow *window = [UIWindow new];
    NSString *scene = [NSString stringWithFormat:@"%p",window];
    [[BDKeyWindowTracker sharedInstance] trackScene:scene keyWindow:window];
    XCTAssertEqualObjects(window, [[BDKeyWindowTracker sharedInstance] keyWindowForScene:scene]);
    [[BDKeyWindowTracker sharedInstance] trackScene:scene keyWindow:nil];
    XCTAssertNil([[BDKeyWindowTracker sharedInstance] keyWindowForScene:scene]);
    [[BDKeyWindowTracker sharedInstance] trackScene:scene keyWindow:window];
    [[BDKeyWindowTracker sharedInstance] removeKeyWindowForScene:scene];
    XCTAssertNil([[BDKeyWindowTracker sharedInstance] keyWindowForScene:scene]);
}

@end
