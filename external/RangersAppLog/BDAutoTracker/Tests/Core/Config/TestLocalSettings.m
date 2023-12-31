//
//  TestLocalSettings.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/12.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <RangersAppLog/BDAutoTrackDefaults.h>
#import <RangersAppLog/BDAutoTrackLocalConfigService.h>
#import <RangersAppLog/BDAutoTrack.h>
#import <RangersAppLog/BDAutoTrackService.h>
#import <RangersAppLog/BDAutoTrackServiceCenter.h>

@interface TestLocalSettings : XCTestCase

@property (nonatomic, strong) BDAutoTrackDefaults *defaults;
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, strong) id mock;
@property (nonatomic, strong) BDAutoTrackConfig *config;

@end

@implementation TestLocalSettings

- (void)setUp {
    self.appID = @"0";
    BDAutoTrackConfig *config = [BDAutoTrackConfig configWithAppID:self.appID launchOptions:nil];
    config.channel = @"App Store";
    config.appName = @"dp_tob_sdk_test2";
    config.gameModeEnable = YES;
    config.logNeedEncrypt = NO;
    config.appID = self.appID;
    config.autoActiveUser = NO;
    self.config = config;

    self.defaults = [BDAutoTrackDefaults defaultsWithAppID:self.appID];
    [self.defaults clearAllData];
    [[BDAutoTrackServiceCenter defaultCenter] unregisterAllServices];
    self.mock = OCMPartialMock([NSUserDefaults standardUserDefaults]);
    OCMStub([self.mock stringForKey:[OCMArg any]]).andReturn(nil);
}

- (void)tearDown {
    [self.mock stopMocking];
}

- (void)testInitParams {
    BDAutoTrackConfig *config = self.config;

    BDAutoTrackLocalConfigService *settings = [[BDAutoTrackLocalConfigService alloc] initWithConfig:config];
    XCTAssertEqual(settings.logNeedEncrypt, config.logNeedEncrypt);
    XCTAssertEqual(settings.autoActiveUser, config.autoActiveUser);
    XCTAssertEqual(settings.serviceVendor, config.serviceVendor);

    XCTAssertEqualObjects(settings.appID, config.appID);
    XCTAssertEqualObjects(settings.channel, config.channel);
    XCTAssertEqualObjects(settings.appName, config.appName);
    XCTAssertEqualObjects(settings.appID, config.appID);
}

- (void)testSetParams {
    BDAutoTrackConfig *config = self.config;

    BDAutoTrackLocalConfigService *settings = [[BDAutoTrackLocalConfigService alloc] initWithConfig:config];

    NSString *userUniqueID = [NSUUID UUID].UUIDString;
    NSString *userAgent = [NSUUID UUID].UUIDString;
    NSString *appLauguage = [NSUUID UUID].UUIDString;
    NSString *appRegion = [NSUUID UUID].UUIDString;

    [settings saveAppRegion:appRegion];
    [settings saveUserAgent:userAgent];
    [settings saveAppLauguage:appLauguage];
    [settings saveUserUniqueID:userUniqueID];

    XCTAssertEqualObjects(settings.appRegion, appRegion);
    XCTAssertEqualObjects(settings.userAgent, userAgent);
    XCTAssertEqualObjects(settings.appLauguage, appLauguage);
    XCTAssertEqualObjects(settings.userUniqueID, userUniqueID);

    BDAutoTrackLocalConfigService *settings1 = [[BDAutoTrackLocalConfigService alloc] initWithConfig:config];
    XCTAssertEqualObjects(settings.appRegion, settings1.appRegion);
    XCTAssertEqualObjects(settings.userAgent, settings1.userAgent);
    XCTAssertEqualObjects(settings.appLauguage, settings1.appLauguage);
    XCTAssertEqualObjects(settings.userUniqueID, settings1.userUniqueID);
}

- (void)testAddParams {
    BDAutoTrackConfig *config = self.config;

    BDAutoTrackLocalConfigService *settings = [[BDAutoTrackLocalConfigService alloc] initWithConfig:config];

    NSString *userUniqueID = [NSUUID UUID].UUIDString;
    NSString *userAgent = [NSUUID UUID].UUIDString;
    NSString *appLauguage = [NSUUID UUID].UUIDString;
    NSString *appRegion = [NSUUID UUID].UUIDString;
    [settings saveAppRegion:appRegion];
    [settings saveUserAgent:userAgent];
    [settings saveAppLauguage:appLauguage];
    [settings saveUserUniqueID:userUniqueID];

    XCTAssertEqualObjects(settings.appRegion, appRegion);
    XCTAssertEqualObjects(settings.userAgent, userAgent);
    XCTAssertEqualObjects(settings.appLauguage, appLauguage);
    XCTAssertEqualObjects(settings.userUniqueID, userUniqueID);
    NSMutableDictionary *result = [NSMutableDictionary new];
    NSMutableDictionary *result1 = [NSMutableDictionary new];
    [settings addSettingParameters:result];
    [settings addSettingParameters:result1];
    XCTAssertEqualObjects(result, result1);

    BDAutoTrackLocalConfigService *settings1 = [[BDAutoTrackLocalConfigService alloc] initWithConfig:config];
    XCTAssertEqualObjects(settings.appRegion, settings1.appRegion);
    XCTAssertEqualObjects(settings.userAgent, settings1.userAgent);
    XCTAssertEqualObjects(settings.appLauguage, settings1.appLauguage);
    XCTAssertEqualObjects(settings.userUniqueID, settings1.userUniqueID);
    NSMutableDictionary *result2 = [NSMutableDictionary new];
    [settings1 addSettingParameters:result2];
    XCTAssertEqualObjects(result, result2);

    [settings1 registerService];
    NSMutableDictionary *result3 = [NSMutableDictionary new];
    bd_addSettingParameters(result3, config.appID);
    XCTAssertEqualObjects(result2, result3);
}

- (void)testQueryParams {
    BDAutoTrackConfig *config = self.config;

    BDAutoTrackLocalConfigService *settings = [[BDAutoTrackLocalConfigService alloc] initWithConfig:config];
    settings.customHeaderBlock = ^NSDictionary<NSString *,id> * _Nonnull{
        return @{@"host":@"123"};
    };
    NSMutableDictionary *result = [NSMutableDictionary new];
    NSMutableDictionary *result1 = [NSMutableDictionary new];
    [settings addSettingParameters:result];
    [settings addSettingParameters:result1];

    NSMutableDictionary *result4 = [NSMutableDictionary new];
    bd_addSettingParameters(result4, config.appID);
    XCTAssertEqual(result4.count, 0);

    [settings registerService];
    NSMutableDictionary *result2 = [NSMutableDictionary new];
    NSMutableDictionary *result3 = [NSMutableDictionary new];
    bd_addSettingParameters(result2, config.appID);
    bd_addSettingParameters(result3, config.appID);
    XCTAssertEqualObjects(result, result2);
    XCTAssertEqualObjects(result1, result3);
}

- (void)testAddParamService {
    BDAutoTrackConfig *config = [BDAutoTrackConfig configWithAppID:self.appID launchOptions:nil];
    config.channel = @"App Store";
    config.appName = @"dp_tob_sdk_test2";
    config.appID = self.appID;

    BDAutoTrackLocalConfigService *settings = [[BDAutoTrackLocalConfigService alloc] initWithConfig:config];

    NSString *userUniqueID = [NSUUID UUID].UUIDString;
    NSString *userAgent = [NSUUID UUID].UUIDString;
    NSString *appLauguage = [NSUUID UUID].UUIDString;
    NSString *appRegion = [NSUUID UUID].UUIDString;
    [settings saveAppRegion:appRegion];
    [settings saveUserAgent:userAgent];
    [settings saveAppLauguage:appLauguage];
    [settings saveUserUniqueID:userUniqueID];
    XCTAssertEqualObjects(settings.appRegion, appRegion);
    XCTAssertEqualObjects(settings.userAgent, userAgent);
    XCTAssertEqualObjects(settings.appLauguage, appLauguage);
    XCTAssertEqualObjects(settings.userUniqueID, userUniqueID);

    NSMutableDictionary *result = [NSMutableDictionary new];
    bd_addSettingParameters(result, config.appID);
    XCTAssertEqual(result.count, 0);

    [settings registerService];
    bd_addSettingParameters(result, config.appID);
    XCTAssertGreaterThan(result.count, 0);
}


@end
