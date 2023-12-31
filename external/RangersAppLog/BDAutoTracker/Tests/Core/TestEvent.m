//
//  TestEvent.m
//  BDAutoTracker_Tests
//
//  Created by 陈奕 on 2019/8/13.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <RangersAppLog/BDAutoTrackDataCenter.h>
#import <RangersAppLog/BDAutoTrack+Private.h>

#import <RangersAppLog/BDAutoTrack.h>

@interface TestEvent : XCTestCase

@property (nonatomic, copy) NSString *appID;
@property (nonatomic, strong) BDAutoTrack *track;

@end

@implementation TestEvent

- (void)setUp {
    self.appID = @"0";
    BDAutoTrackConfig *config = [BDAutoTrackConfig configWithAppID:self.appID launchOptions:nil];
    config.channel = @"App Store";
    config.appName = @"dp_tob_sdk_test2";
    config.appID = self.appID;

    self.track = [BDAutoTrack trackWithConfig:config];
}

- (void)test_event_fail {
    XCTAssertFalse([self.track eventV3:@"" params:nil], @"event 不能为空");
    XCTAssertFalse([self.track eventV3:@"test" params:@{@(1):@"test"}], @" 序列化失败");
}

- (void)test_event_success {
    XCTAssertTrue([self.track eventV3:@"test any" params:@{}]);
    XCTAssertTrue([self.track eventV3:@"test any" params:nil]);
    XCTAssertTrue([self.track eventV3:@"test any"]);
}

@end
