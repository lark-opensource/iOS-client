//
//  TestRemoteConfig.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/12.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RangersAppLog/BDAutoTrackDefaults.h>
#import <RangersAppLog/BDAutoTrackRemoteSettingService.h>

@interface TestRemoteConfig : XCTestCase

@property (nonatomic, strong) BDAutoTrackDefaults *defaults;
@property (nonatomic, copy) NSString *appID;

@end

@implementation TestRemoteConfig

- (void)setUp {
    self.appID = @"0";
    self.defaults = [BDAutoTrackDefaults defaultsWithAppID:self.appID];
    [self.defaults clearAllData];
}

- (void)testDefaultValue {
    BDAutoTrackRemoteSettingService *settings = [[BDAutoTrackRemoteSettingService alloc] initWithAppID:self.appID];
    /// default 60
    XCTAssertGreaterThanOrEqual(settings.batchInterval, 60);
    XCTAssertGreaterThanOrEqual(settings.abFetchInterval, 600);
    XCTAssertFalse(settings.abTestEnabled);
    XCTAssertTrue(settings.autoTrackEnabled);
    XCTAssertFalse(settings.skipLaunch);
    XCTAssertNil(settings.realTimeEvents);
}

- (void)testUpdateValue {
    CFTimeInterval batchInterval = 20 + arc4random() % 60;
    CFTimeInterval abFetchInterval = 600 + arc4random() % 60;
    BOOL abTestEnabled = (arc4random() % 2) == 0;
    BOOL autoTrackEnabled = (arc4random() % 2) == 0;
    BOOL skipLaunch = (arc4random() % 2) == 0;
    BOOL send_launch_timely = !skipLaunch;
    NSArray *realTimeEvents = @[@"test"];

    NSDictionary *response = @{@"config":@{@"batch_event_interval":@(batchInterval),
                                           @"abtest_fetch_interval":@(abFetchInterval),
                                           @"bav_ab_config":@(abTestEnabled),
                                           @"bav_log_collect":@(autoTrackEnabled),
                                           @"send_launch_timely":@(send_launch_timely),
                                           @"real_time_events":realTimeEvents,
                                           },
                               };
    BDAutoTrackRemoteSettingService *settings = [[BDAutoTrackRemoteSettingService alloc] initWithAppID:self.appID];
    [settings updateRemoteWithResponse:response];
    [settings registerService];
    XCTAssertEqualObjects(bd_remoteSettingsForAppID(self.appID), settings);

    XCTAssertEqual(batchInterval, settings.batchInterval);
    XCTAssertEqual(abFetchInterval, settings.abFetchInterval);
    XCTAssertEqual(abTestEnabled, settings.abTestEnabled);
    XCTAssertEqual(skipLaunch, settings.skipLaunch);
    XCTAssertEqualObjects(realTimeEvents, settings.realTimeEvents);

    BDAutoTrackRemoteSettingService *settings1 = [[BDAutoTrackRemoteSettingService alloc] initWithAppID:self.appID];
    XCTAssertEqual(settings1.batchInterval, settings.batchInterval);
    XCTAssertEqual(settings1.abFetchInterval, settings.abFetchInterval);
    XCTAssertEqual(settings1.abTestEnabled, settings.abTestEnabled);
    XCTAssertEqual(settings1.skipLaunch, settings.skipLaunch);
    XCTAssertEqualObjects(settings1.realTimeEvents, settings.realTimeEvents);
}

- (void)testIntervalValue {
    CFTimeInterval batchInterval = 20 + arc4random() % 60;
    CFTimeInterval abFetchInterval = 600 + arc4random() % 60;

    NSDictionary *response = @{@"config":@{@"batch_event_interval":@(batchInterval),
                                           @"abtest_fetch_interval":@(abFetchInterval),
                                           },
                               };
    BDAutoTrackRemoteSettingService *settings = [[BDAutoTrackRemoteSettingService alloc] initWithAppID:self.appID];
    [settings updateRemoteWithResponse:response];
    /// min 20
    XCTAssertGreaterThanOrEqual(settings.batchInterval, 20);
    XCTAssertGreaterThanOrEqual(settings.abFetchInterval, 600);
    XCTAssertEqual(batchInterval, settings.batchInterval);
    XCTAssertEqual(abFetchInterval, settings.abFetchInterval);


    CFTimeInterval batchIntervalLess = 20.0 - arc4random() % 10;
    CFTimeInterval abFetchIntervalLess = 600.0 - arc4random() % 600;

    NSDictionary *responseLess = @{@"config":@{@"batch_event_interval":@(batchIntervalLess),
                                               @"abtest_fetch_interval":@(abFetchIntervalLess),
                                               },
                                   };
    [settings updateRemoteWithResponse:responseLess];
    /// will
    XCTAssertGreaterThanOrEqual(settings.batchInterval, 20);
    XCTAssertGreaterThanOrEqual(settings.abFetchInterval, 600);
}

@end
