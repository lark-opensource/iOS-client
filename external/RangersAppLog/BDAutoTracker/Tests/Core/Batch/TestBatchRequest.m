//
//  TestBatchRequest.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/15.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RangersAppLog/BDAutoTrackNetworkRequest.h>
#import <RangersAppLog/BDAutoTrackBatchService.h>
#import <RangersAppLog/BDAutoTrackRegisterService.h>
#import <OCMock/OCMock.h>
#import <RangersAppLog/BDAutoTrackParamters.h>
#import <RangersAppLog/BDAutoTrackRemoteSettingService.h>

#import <RangersAppLog/BDAutoTrackLocalConfigService.h>
#import "AppLogTestTool.h"


@interface TestBatchRequest : XCTestCase
@property (nonatomic, copy) NSString *appID;
@end

@implementation TestBatchRequest

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


@end
