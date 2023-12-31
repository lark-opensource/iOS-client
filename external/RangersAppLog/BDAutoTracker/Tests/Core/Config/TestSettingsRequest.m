//
//  TestSettingsRequest.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/15.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RangersAppLog/BDAutoTrackNetworkRequest.h>
#import <RangersAppLog/BDAutoTrackSettingsRequest.h>
#import <RangersAppLog/BDAutoTrackRegisterService.h>
#import <OCMock/OCMock.h>
#import <RangersAppLog/BDAutoTrackNotifications.h>
#import <RangersAppLog/BDAutoTrackParamters.h>
#import <RangersAppLog/BDAutoTrackRemoteSettingService.h>

#import <RangersAppLog/BDAutoTrackLocalConfigService.h>
#import "AppLogTestTool.h"

@interface TestSettingsRequest : XCTestCase

@property (nonatomic, copy) NSString *appID;

@end

@implementation TestSettingsRequest

- (void)setUp {
    [super setUp];
    self.appID = @"0";

    BDAutoTrackConfig *config = [BDAutoTrackConfig configWithAppID:self.appID launchOptions:nil];
    config.channel = @"App Store";
    config.appName = @"dp_tob_sdk_test2";
    config.appID = self.appID;
    BDAutoTrackLocalConfigService *settings = [[BDAutoTrackLocalConfigService alloc] initWithConfig:config];
    [settings registerService];
}

- (void)testRequest {
    BDAutoTrackSettingsRequest *request = [[BDAutoTrackSettingsRequest alloc] initWithAppID:self.appID next:nil];
    [request startRequestWithRetry:1];

//    OCMVerifyAllWithDelay(mock, 4);
}

- (void)testRequestFail {
    BDAutoTrackSettingsRequest *request = [[BDAutoTrackSettingsRequest alloc] initWithAppID:self.appID next:nil];
    id mock = OCMPartialMock(request);
    OCMStub([mock handleResponse:[OCMArg any]]).andReturn(NO);
    OCMExpect([mock startRequestWithRetry:0]);
    [request startRequestWithRetry:1];

    OCMVerifyAllWithDelay(mock, 4);
}

@end
