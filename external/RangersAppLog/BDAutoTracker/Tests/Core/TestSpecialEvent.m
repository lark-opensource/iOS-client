//
//  TestSpecialEvent.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/11.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <RangersAppLog/BDAutoTrack+Special.h>
#import <RangersAppLog/BDAutoTrackSwizzle.h>
#import <RangersAppLog/BDAutoTrackDataCenter.h>
#import <RangersAppLog/BDAutoTrack+Private.h>
#import <RangersAppLog/BDTrackerCoreConstants.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface TestSpecialEvent : XCTestCase

@property (nonatomic, copy) NSString *appID;
@property (nonatomic, strong) BDAutoTrack *track;

@end

@implementation TestSpecialEvent

- (void)setUp {
    self.appID = @"0";
    BDAutoTrackConfig *config = [BDAutoTrackConfig configWithAppID:self.appID launchOptions:nil];
    config.channel = @"App Store";
    config.appName = @"dp_tob_sdk_test2";
    config.appID = self.appID;

    self.track = [BDAutoTrack trackWithConfig:config];
}

- (void)testSpecialParam {
    NSDictionary *param = [BDAutoTrack specialParamsWitAppID:@"111"
                                                     appName:@"name"
                                                        type:@"type"];
    XCTAssertNotNil(param);
    XCTAssertEqual(param.count, 4);
    XCTAssertEqualObjects(param, [BDAutoTrack specialParamsWitAppID:@"111"
                                                            appName:@"name"
                                                               type:@"type"]);
    XCTAssertNotEqualObjects(param, [BDAutoTrack specialParamsWitAppID:@"112"
                                                               appName:@"name"
                                                                  type:@"type"]);
    XCTAssertNotEqualObjects(param, [BDAutoTrack specialParamsWitAppID:@"111"
                                                               appName:@"name2"
                                                                  type:@"type"]);
    XCTAssertNotEqualObjects(param, [BDAutoTrack specialParamsWitAppID:@"111"
                                                               appName:@"name"
                                                                  type:@"type1"]);
}

- (void)test_special_fail {
    NSDictionary *param = @{};
    XCTAssertFalse([self.track eventV3:@"xxx" params:@{@"test":@""} specialParams:param]);
    
    param = [BDAutoTrack specialParamsWitAppID:@"111"
                                       appName:@"name"
                                          type:@"type"];
    XCTAssertFalse([self.track eventV3:@"" params:nil specialParams:param]);
    XCTAssertFalse([self.track eventV3:@"test" params:@{@(1):@"test"} specialParams:param]);
}

- (void)test_custom_fail {
    NSArray *allInternalTables = @[BDAutoTrackTableLaunch,
                                   BDAutoTrackTableTerminate,
                                   BDAutoTrackTableEventV3,
                                   BDAutoTrackTableUIEvent,
                                   BDAutoTrackTableExtraEvent,
                                   kBDAutoTrackHeader,
                                   kBDAutoTrackTimeSync,
                                   kBDAutoTrackMagicTag];
    for (NSString *custom in allInternalTables) {
        XCTAssertFalse([self.track customEvent:custom params:@{}]);
    }
    XCTAssertFalse([self.track customEvent:@"" params:@{}]);
    XCTAssertFalse([self.track customEvent:@"test" params:@{@(1):@"test"}]);
}

- (void)test_event_success {
    id dataCenterMock = OCMPartialMock(self.track.dataCenter);
    NSDictionary *param = [BDAutoTrack specialParamsWitAppID:@"111"
                                                     appName:@"name"
                                                        type:@"type"];

    OCMExpect([dataCenterMock trackUserEventWithData:[OCMArg any]]);
    XCTAssertTrue([self.track eventV3:@"test any" params:@{} specialParams:param]);


    OCMExpect([dataCenterMock trackWithTableName:[OCMArg any] data:[OCMArg any]]);
    XCTAssertTrue([self.track customEvent:@"test" params:@{@"test":@"test"}]);

    OCMVerifyAll(dataCenterMock);
    [dataCenterMock stopMocking];
}

@end
#pragma clang diagnostic pop
