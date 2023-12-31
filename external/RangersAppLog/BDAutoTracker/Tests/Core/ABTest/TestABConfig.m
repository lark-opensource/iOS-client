//
//  TestABConfig.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/12.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <RangersAppLog/BDAutoTrackABConfig.h>
#import <RangersAppLog/BDAutoTrackDefaults.h>
#import <RangersAppLog/BDAutoTrackServiceCenter.h>
#import <RangersAppLog/BDAutoTrackLocalConfigService.h>
#import <RangersAppLog/BDAutoTrackRemoteSettingService.h>

@interface TestABConfig : XCTestCase

@property (nonatomic, strong) id defaultsMock;
@property (nonatomic, strong) BDAutoTrackDefaults *defaults;
@property (nonatomic, copy) NSString *appID;

@end

@implementation TestABConfig

- (void)setUp {
    self.appID = @"0";
    self.defaults = [BDAutoTrackDefaults defaultsWithAppID:self.appID];
    [self.defaults clearAllData];
    self.defaultsMock = OCMPartialMock(self.defaults);
    [[BDAutoTrackServiceCenter defaultCenter] unregisterAllServices];

    BDAutoTrackConfig *config = [BDAutoTrackConfig configWithAppID:self.appID launchOptions:nil];
    config.channel = @"App Store";
    config.appName = @"dp_tob_sdk_test2";
    config.appID = self.appID;
    BDAutoTrackLocalConfigService *settings = [[BDAutoTrackLocalConfigService alloc] initWithConfig:config];
    [settings registerService];

    BDAutoTrackRemoteSettingService *remote = [[BDAutoTrackRemoteSettingService alloc] initWithAppID:self.appID];
    [remote registerService];
}

- (void)tearDown {
    [self.defaultsMock stopMocking];
}

- (void)testEmptyABConfig {
    OCMStub([self.defaultsMock arrayValueForKey:[OCMArg any]]).andReturn(nil);
    OCMStub([self.defaultsMock dictionaryValueForKey:[OCMArg any]]).andReturn(nil);
    OCMStub([self.defaultsMock stringValueForKey:[OCMArg any]]).andReturn(nil);

    BDAutoTrackABConfig *config = [[BDAutoTrackABConfig alloc] initWithAppID:self.appID];
    [config registerService];
    XCTAssertEqual(config.currentRawData.count, 0);
    XCTAssertNil([config sendableABVersions]);
    XCTAssertNil([config allABVersions]);
    XCTAssertEqual([config allABTestConfigs].count, 0);

//    NSMutableDictionary *result0 = [NSMutableDictionary new];
//    NSMutableDictionary *result1 = [NSMutableDictionary new];
//    bd_abAddParameters(result0, self.appID, NO);
//    bd_abAddParameters(result1, self.appID, NO);
//    XCTAssertEqualObjects(result0, result1);
//    XCTAssertEqual(result0.count, 0);
}

- (void)testABConfigValues {
    NSDictionary *target = @{@"control_grand_prize": @{
                                 @"vid": @"1363",
                                 @"val": @0,
                             },
                             @"control_float_ball_banner": @{
                                 @"vid": @"1355",
                                 @"val": @1,
                             },
                             };
    NSDictionary *targetAll = @{@"control_grand_prize":@0,
                                @"control_float_ball_banner":@1,
                                };
    OCMStub([self.defaultsMock dictionaryValueForKey:[OCMArg any]]).andReturn(target);
    BDAutoTrackABConfig *config = [[BDAutoTrackABConfig alloc] initWithAppID:self.appID];
    [config registerService];
    XCTAssertEqualObjects(config.currentRawData, target);
    XCTAssertEqualObjects([config allABTestConfigs], targetAll);
    

    XCTAssertNil([config sendableABVersions]);
    
    NSString *allABVersions = [config allABVersions];
    XCTAssertTrue([allABVersions containsString:@"1363"]);
    XCTAssertTrue([allABVersions containsString:@"1355"]);
    XCTAssertNotNil([config allABVersions]);

    [config getConfig:@"control_grand_prize" defaultValue:nil];
    XCTAssertNotNil([config sendableABVersions]);
    XCTAssertEqualObjects([config sendableABVersions], @"1363");
    NSString *allABVersions1 = [config allABVersions];
    XCTAssertEqualObjects(allABVersions, allABVersions1);

    [config getConfig:@"control_float_ball_banner" defaultValue:nil];
    XCTAssertNotNil([config sendableABVersions]);
    XCTAssertTrue([[config sendableABVersions] containsString:@"1363"]);
    XCTAssertTrue([[config sendableABVersions] containsString:@"1355"]);

    BDAutoTrackABConfig *config2 = [[BDAutoTrackABConfig alloc] initWithAppID:self.appID];
    XCTAssertNotNil([config2 sendableABVersions]);
    XCTAssertTrue([[config2 sendableABVersions] containsString:@"1363"]);
    XCTAssertTrue([[config2 sendableABVersions] containsString:@"1355"]);
    XCTAssertEqualObjects(allABVersions, [config2 allABVersions]);
    XCTAssertEqualObjects(config2.currentRawData, target);
    XCTAssertEqualObjects([config2 allABTestConfigs], targetAll);
    
//    NSMutableDictionary *result0 = [NSMutableDictionary new];
//    NSMutableDictionary *result1 = [NSMutableDictionary new];
//    bd_abAddParameters(result0, self.appID, NO);
//    bd_abAddParameters(result1, self.appID, NO);
//    XCTAssertEqualObjects(result0, result1);
}

- (void)testUpdate {
    NSDictionary *target = @{@"control_grand_prize": @{
                                     @"vid": @"1363",
                                     @"val": @0,
                                     },
                             @"control_float_ball_banner": @{
                                     @"vid": @"1355",
                                     @"val": @1,
                                     },
                             };
    NSDictionary *targetAll = @{@"control_grand_prize":@0,
                                @"control_float_ball_banner":@1,
                                };

    BDAutoTrackABConfig *config = [[BDAutoTrackABConfig alloc] initWithAppID:self.appID];
    /// emtpy first
    XCTAssertEqual(config.currentRawData.count, 0);
    XCTAssertNil([config sendableABVersions]);
    XCTAssertNil([config allABVersions]);
    XCTAssertEqual([config allABTestConfigs].count, 0);
    [config registerService];
    [config updateABConfigWithRawData:target postNotification:YES];

    XCTAssertEqualObjects([config allABTestConfigs], targetAll);
    XCTAssertEqualObjects(config.currentRawData, target);
    XCTAssertNil([config sendableABVersions]);
    NSString *allABVersions = [config allABVersions];
    XCTAssertTrue([allABVersions containsString:@"1363"]);
    XCTAssertTrue([allABVersions containsString:@"1355"]);
    XCTAssertNotNil([config allABVersions]);

    [config getConfig:@"control_grand_prize" defaultValue:nil];
    XCTAssertNotNil([config sendableABVersions]);
    XCTAssertEqualObjects([config sendableABVersions], @"1363");
    NSString *allABVersions1 = [config allABVersions];
    XCTAssertEqualObjects(allABVersions, allABVersions1);

    [config getConfig:@"control_float_ball_banner" defaultValue:nil];
    XCTAssertNotNil([config sendableABVersions]);
    XCTAssertTrue([[config sendableABVersions] containsString:@"1363"]);
    XCTAssertTrue([[config sendableABVersions] containsString:@"1355"]);

    BDAutoTrackABConfig *config2 = [[BDAutoTrackABConfig alloc] initWithAppID:self.appID];
    XCTAssertNotNil([config2 sendableABVersions]);
    XCTAssertTrue([[config2 sendableABVersions] containsString:@"1363"]);
    XCTAssertTrue([[config2 sendableABVersions] containsString:@"1355"]);
    XCTAssertEqualObjects(allABVersions, [config2 allABVersions]);
    XCTAssertEqualObjects(config2.currentRawData, target);
    XCTAssertEqualObjects([config2 allABTestConfigs], targetAll);

//    NSMutableDictionary *result0 = [NSMutableDictionary new];
//    NSMutableDictionary *result1 = [NSMutableDictionary new];
//    bd_abAddParameters(result0, self.appID, NO);
//    bd_abAddParameters(result1, self.appID, NO);
//    XCTAssertEqualObjects(result0, result1);
}

@end
