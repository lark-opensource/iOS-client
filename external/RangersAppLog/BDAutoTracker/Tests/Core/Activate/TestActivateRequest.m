//
//  TestActivateRequest.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/15.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RangersAppLog/BDAutoTrackNetworkRequest.h>
#import <RangersAppLog/BDAutoTrackRegisterService.h>
#import <OCMock/OCMock.h>
#import <RangersAppLog/BDAutoTrackActivateRequest.h>
#import <RangersAppLog/BDAutoTrackParamters.h>
#import <RangersAppLog/BDAutoTrackNotifications.h>
#import <RangersAppLog/BDAutoTrackLocalConfigService.h>

#import "AppLogTestTool.h"

@interface TestActivateRequest : XCTestCase

@property (nonatomic, copy) NSString *appID;

@end

@implementation TestActivateRequest

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



- (void)testNotification {
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    [userInfo setValue:self.appID forKey:kBDAutoTrackNotificationAppID];
    BDAutoTrackActivateRequest *request = [[BDAutoTrackActivateRequest alloc] initWithAppID:self.appID next:nil];
    request.needActiveUser = YES;
    id mock = OCMPartialMock(request);
    OCMStub([mock handleResponse:[OCMArg any]]).andReturn(NO);
    OCMExpect([mock startRequestWithRetry:3]);
    [[NSNotificationCenter defaultCenter] postNotificationName:BDAutoTrackNotificationRegisterSuccess
                                                        object:nil
                                                      userInfo:userInfo];

    OCMVerifyAllWithDelay(mock, 4);
}

@end
