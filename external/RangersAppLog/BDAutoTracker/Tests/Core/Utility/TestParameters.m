//
//  TestParameters.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/12.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RangersAppLog/BDAutoTrackParamters.h>
#import <RangersAppLog/BDTrackerCoreConstants.h>
#import <RangersAppLog/NSDictionary+BDAutoTrack.h>
#import "BDAutoTrackServiceCenter.h"
#import <RangersAppLog/BDTrackerCoreConstants.h>
#import <OneKit/NSDictionary+OK.h>
#import <OneKit/OKApplicationInfo.h>
#import <RangersAppLog/BDAutoTrackUtility.h>

@interface TestParameters : XCTestCase

@end

@implementation TestParameters

- (void)testQueryNetworkParamtersEqual {
    NSMutableDictionary *result1 = [NSMutableDictionary new];
    NSMutableDictionary *result2 = [NSMutableDictionary new];
    XCTAssertEqualObjects(result2, result1);
    bd_addQueryNetworkParams(result1, @"123");
    bd_addQueryNetworkParams(result2, @"123");
    XCTAssertEqualObjects(result2, result1);
}

- (void)testQueryNetworkParams {
    NSMutableDictionary *result = [NSMutableDictionary new];
    bd_addQueryNetworkParams(result, @"123");
    XCTAssertTrue(result[@"idfv"]);
    
    if ([OKApplicationInfo sharedInstance].appVersion) {
        XCTAssertTrue(result[kBDAutoTrackerVersionCode]);
    } else {
        XCTAssertNil(result[kBDAutoTrackerVersionCode]);
    }
}

- (void)testBodyNetworkParamtersEqual {
    NSMutableDictionary *result1 = [NSMutableDictionary new];
    NSMutableDictionary *result2 = [NSMutableDictionary new];
    XCTAssertEqualObjects(result2, result1);
    bd_addBodyNetworkParams(result1, @"123");
    bd_addBodyNetworkParams(result2, @"123");
    XCTAssertEqualObjects(result2, result1);
}

- (void)testBodyNetworkParams {
    NSMutableDictionary *result = [NSMutableDictionary new];
    bd_addBodyNetworkParams(result, @"123");
    XCTAssertTrue(result[kBDAutoTrackMCCMNC]);
    XCTAssertTrue(result[kBDAutoTrackCarrier]);
    XCTAssertTrue(result[kBDAutoTrackAccess]);
    XCTAssertTrue(result[kBDAutoTrackTimeZoneOffSet]);
    XCTAssertTrue(result[kBDAutoTrackTimeZone]);
    XCTAssertTrue(result[kBDAutoTrackTimeZoneName]);
    XCTAssertTrue(result[kBDAutoTrackVendorID]);
    XCTAssertTrue(result[kBDAutoTrackRegion]);
    XCTAssertTrue(result[kBDAutoTrackLanguage]);
    XCTAssertTrue(result[kBDAutoTrackResolution]);
    XCTAssertTrue(result[kBDAutoTrackIsJailBroken]);
    XCTAssertTrue(result[kBDAutoTrackPackage]);
    XCTAssertTrue(result[kBDAutoTrackAPPDisplayName]);
    XCTAssertTrue(result[kBDAutoTrackAPPBuildVersion]);
}

- (void)testSharedNetworkParams {
    NSMutableDictionary *queryParams = [NSMutableDictionary new];
    bd_addQueryNetworkParams(queryParams, @"123");
    NSMutableDictionary *bodyParams = [NSMutableDictionary new];
    bd_addBodyNetworkParams(bodyParams, @"123");
    
    for (NSDictionary *result in @[queryParams, bodyParams]) {
        XCTAssertTrue(result[kBDAutoTrackPlatform]);
        XCTAssertTrue(result[kBDAutoTrackSDKLib]);
        XCTAssertTrue(result[kBDAutoTrackerSDKVersion]);
        XCTAssertTrue(result[kBDAutoTrackOS]);
        XCTAssertTrue(result[kBDAutoTrackOSVersion]);
        if ([OKApplicationInfo sharedInstance].appVersion) {
            XCTAssertTrue(result[kBDAutoTrackAPPVersion]);
        } else {
            XCTAssertNil(result[kBDAutoTrackAPPVersion]);
        }
        XCTAssertTrue(result[kBDAutoTrackDecivceModel]);
        XCTAssertTrue(result[kBDAutoTrackIsUpgradeUser]);
        XCTAssertTrue(result[@"idfa"]);
    }
}

- (void)testHeaderField {
    NSString *appID = [NSUUID UUID].UUIDString;
    NSMutableDictionary *result1 = bd_headerField(YES, appID);
    NSMutableDictionary *result2 = bd_headerField(NO, appID);
    XCTAssertNotNil(result1);
    XCTAssertNotNil(result2);
    XCTAssertNotEqualObjects(result1, result2);
    XCTAssertEqualObjects(result2, bd_headerField(NO, appID));
    XCTAssertEqualObjects(result1, bd_headerField(YES, appID));
}

- (void)testTimeSync {
    [[NSUserDefaults standardUserDefaults] setObject:@"kTimeSyncStorageKey" forKey:@"kTimeSyncStorageKey"];
    NSDictionary *result1 = bd_timeSync();
    XCTAssertNotNil(result1);
    
    long long interval = (long long)[[NSDate date] timeIntervalSince1970];
    NSDictionary *responseDict = @{kBDAutoTrackServerTime:@(interval)};
    bd_updateServerTime(responseDict);
    XCTestExpectation *expectation = [self expectationWithDescription:@"testTimeSync"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSDictionary *result2 = bd_timeSync();
        XCTAssertNotNil(result2);
        long long interval2 = [result2 ok_longlongValueForKey:kBDAutoTrackServerTime];
        XCTAssertEqual(interval, interval2);
        [expectation fulfill];
    });

    [self waitForExpectations:@[expectation] timeout: 0.2];
}

- (void)testResponseValidate {
    NSDictionary *responseDict = @{kBDAutoTrackMagicTag:BDAutoTrackMagicTag};
    XCTAssertTrue(bd_isValidResponse(responseDict));
    XCTAssertTrue(bd_isValidResponse(responseDict));

    XCTAssertFalse(bd_isValidResponse(@{}));
    XCTAssertFalse(bd_isValidResponse(nil));
    XCTAssertFalse(bd_isValidResponse(@{kBDAutoTrackMagicTag:@""}));

    XCTAssertFalse(bd_isResponseMessageSuccess(responseDict));
    XCTAssertFalse(bd_isResponseMessageSuccess(@{}));
    XCTAssertFalse(bd_isResponseMessageSuccess(nil));
    XCTAssertFalse(bd_isResponseMessageSuccess(@{kBDAutoTrackMessage:@""}));

    responseDict = @{kBDAutoTrackMessage:BDAutoTrackMessageSuccess};
    XCTAssertTrue(bd_isResponseMessageSuccess(responseDict));
    XCTAssertTrue(bd_isResponseMessageSuccess(responseDict));
}

- (void)testCharacters {
    XCTAssertNotNil(bd_URLAllowedCharacters());
    XCTAssertEqualObjects(bd_URLAllowedCharacters(), bd_URLAllowedCharacters());
    XCTAssertEqual(bd_URLAllowedCharacters(), bd_URLAllowedCharacters());
}

- (void)testEventParameters {
    NSMutableDictionary *result0 = [NSMutableDictionary new];
    NSMutableDictionary *result1 = [NSMutableDictionary new];
    NSMutableDictionary *result2 = [NSMutableDictionary new];
    XCTAssertNotNil(result2);
    XCTAssertNotNil(result1);
    XCTAssertNotNil(result0);
    bd_addEventParameters(result1);
    bd_addEventParameters(result0);
    
    XCTAssertEqualObjects([result0 objectForKey:kBDAutoTrackEventSessionID], [result1 objectForKey:kBDAutoTrackEventSessionID]);
    XCTAssertEqualObjects([result0 objectForKey:kBDAutoTrackEventTime], [result1 objectForKey:kBDAutoTrackEventTime]);
    XCTAssertEqualObjects([result0 objectForKey:kBDAutoTrackEventNetWork], [result1 objectForKey:kBDAutoTrackEventNetWork]);
    XCTestExpectation *expectation = [self expectationWithDescription:@"testEventParameters"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        bd_addEventParameters(result2);
        XCTAssertNotEqualObjects(result1, result2);
        [expectation fulfill];
    });

    [self waitForExpectations:@[expectation] timeout: 0.2];
}

- (void)testBase64Constant {
    XCTAssertTrue([f_kBDAutoTrackIDFA() isEqualToString:@"idfa"]);
}
@end
