//
//  TestRegisterService.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/13.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RangersAppLog/BDAutoTrackDefaults.h>
#import <RangersAppLog/BDAutoTrackService.h>
#import <RangersAppLog/BDAutoTrackServiceCenter.h>
#import <RangersAppLog/BDAutoTrackRegisterService.h>
#import <RangersAppLog/BDTrackerCoreConstants.h>
#import <RangersAppLog/BDAutoTrackLocalConfigService.h>

#import <RangersAppLog/BDAutoTrack.h>

#import "AppLogTestTool.h"

@interface TestRegisterService : XCTestCase

@property (nonatomic, strong) BDAutoTrackDefaults *defaults;
@property (nonatomic, copy) NSString *appID;

@end

@implementation TestRegisterService

- (void)setUp {
    self.appID = @"0";
    self.defaults = [BDAutoTrackDefaults defaultsWithAppID:self.appID];
    [self.defaults clearAllData];

    BDAutoTrackConfig *config = [BDAutoTrackConfig configWithAppID:self.appID launchOptions:nil];
    config.channel = @"App Store";
    config.appName = @"dp_tob_sdk_test2";
    config.appID = self.appID;
    BDAutoTrackLocalConfigService *settings = [[BDAutoTrackLocalConfigService alloc] initWithConfig:config];
    [settings registerService];
}

- (void)testAvailable {
    BDAutoTrackRegisterService *service = [[BDAutoTrackRegisterService alloc] initWithAppID:self.appID];
    [service registerService];
    XCTAssertFalse([service serviceAvailable]);
    XCTAssertFalse(bd_registerServiceAvailableForAppID(self.appID));
}

- (void)testUpdateParameters {
    BDAutoTrackRegisterService *service = [[BDAutoTrackRegisterService alloc] initWithAppID:self.appID];
    [service registerService];
    
    NSDictionary *response = [AppLogTestTool fakeRegisterResult];
    XCTAssertFalse([service serviceAvailable]);
    XCTAssertFalse(bd_registerServiceAvailableForAppID(self.appID));
    XCTAssertTrue([service updateParametersWithResponse:response]);
    XCTAssertTrue([service serviceAvailable]);
    XCTAssertTrue(bd_registerServiceAvailableForAppID(self.appID));

    NSMutableDictionary *result = [NSMutableDictionary new];
    bd_registeredAddParameters(result, self.appID);
    XCTAssertNotNil([result objectForKey:kBDAutoTrackBDDid]);
    XCTAssertNotNil([result objectForKey:kBDAutoTrackSSID]);
    XCTAssertNotNil([result objectForKey:kBDAutoTrackInstallID]);
}

- (void)testReloadParameters {
    BDAutoTrackRegisterService *service = [[BDAutoTrackRegisterService alloc] initWithAppID:self.appID];
    [service registerService];


    NSDictionary *response = nil;

    XCTAssertFalse([service serviceAvailable]);
    XCTAssertFalse(bd_registerServiceAvailableForAppID(self.appID));

    response = @{
        kBDAutoTrackInstallID : @"123",
    };
    /// wrong data test
    XCTAssertFalse([service updateParametersWithResponse:@{}]);
    XCTAssertFalse([service updateParametersWithResponse:response]);
    XCTAssertFalse([service serviceAvailable]);
    XCTAssertFalse(bd_registerServiceAvailableForAppID(self.appID));

    response = [AppLogTestTool fakeRegisterResult];
    XCTAssertTrue([service updateParametersWithResponse:response]);
    XCTAssertTrue([service serviceAvailable]);
    XCTAssertTrue(bd_registerServiceAvailableForAppID(self.appID));
}

@end
