//
//  TestService.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/12.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RangersAppLog/BDAutoTrackService.h>
#import <RangersAppLog/BDAutoTrackServiceCenter.h>
#import <objc/runtime.h>

@interface TestService : XCTestCase

@end

@implementation TestService

- (void)setUp {
    [[BDAutoTrackServiceCenter defaultCenter] unregisterAllServices];
}

- (void)testRegistser {
    NSString *appID = @"123";
    NSString *serviceName = @"Test";
    XCTAssertNil([[BDAutoTrackServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);
    BDAutoTrackService *service1 = [[BDAutoTrackService alloc] initWithAppID:appID];
    service1.serviceName = serviceName;
    [service1 registerService];

    XCTAssertTrue([service1 serviceAvailable]);

    XCTAssertNotNil([[BDAutoTrackServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);
    XCTAssertEqualObjects(service1, [[BDAutoTrackServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);
    XCTAssertEqual(service1, [[BDAutoTrackServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);

    BDAutoTrackService *service2 = [[BDAutoTrackService alloc] initWithAppID:appID];
    service2.serviceName = serviceName;
    [[BDAutoTrackServiceCenter defaultCenter] registerService:service2];
    XCTAssertTrue([service2 serviceAvailable]);
    XCTAssertNotNil([[BDAutoTrackServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);
    XCTAssertEqualObjects(service2, [[BDAutoTrackServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);
    XCTAssertEqual(service2, [[BDAutoTrackServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);
    XCTAssertNotEqual(service1, [[BDAutoTrackServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);
    XCTAssertNotEqualObjects(service1, [[BDAutoTrackServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);

    BDAutoTrackService *service4 = [[BDAutoTrackService alloc] initWithAppID:appID];
    BDAutoTrackService *service5 = [[BDAutoTrackService alloc] initWithAppID:@""];
    service5.serviceName = serviceName;
    [[BDAutoTrackServiceCenter defaultCenter] registerService:service4];
    [[BDAutoTrackServiceCenter defaultCenter] registerService:service5];
    [[BDAutoTrackServiceCenter defaultCenter] unregisterService:service4];
    [[BDAutoTrackServiceCenter defaultCenter] unregisterService:service5];
    XCTAssertNil([[BDAutoTrackServiceCenter defaultCenter] serviceForName:@"" appID:appID]);
    XCTAssertNil([[BDAutoTrackServiceCenter defaultCenter] serviceForName:serviceName appID:@""]);
}

- (void)testUnregistser {
    NSString *appID = @"123";
    NSString *serviceName = @"Test";
    XCTAssertNil([[BDAutoTrackServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);
    BDAutoTrackService *service1 = [[BDAutoTrackService alloc] initWithAppID:appID];
    service1.serviceName = serviceName;
    [service1 registerService];
    XCTAssertTrue([service1 serviceAvailable]);
    XCTAssertNotNil([[BDAutoTrackServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);
    XCTAssertEqualObjects(service1, [[BDAutoTrackServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);
    XCTAssertEqual(service1, [[BDAutoTrackServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);

    [service1 unregisterService];
    XCTAssertNil([[BDAutoTrackServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);

    [service1 registerService];
    XCTAssertNotNil([[BDAutoTrackServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);
    [[BDAutoTrackServiceCenter defaultCenter] unregisterService:service1];
    XCTAssertNil([[BDAutoTrackServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);

    [service1 registerService];
    XCTAssertNotNil([[BDAutoTrackServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);
    [[BDAutoTrackServiceCenter defaultCenter] unregisterAllServices];
    XCTAssertNil([[BDAutoTrackServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);
}

- (void)testServices {
    NSString *appID = @"123";
    NSString *serviceName = @"Test";
    BDAutoTrackService *service1 = [[BDAutoTrackService alloc] initWithAppID:appID];
    service1.serviceName = serviceName;
    [service1 registerService];

    BDAutoTrackService *service2 = [[BDAutoTrackService alloc] initWithAppID:@"124"];
    service2.serviceName = serviceName;
    [service2 registerService];

    NSArray<id<BDAutoTrackService>> *services = [[BDAutoTrackServiceCenter defaultCenter] servicesForName:serviceName];
    XCTAssertTrue([services containsObject:service1]);
    XCTAssertTrue([services containsObject:service2]);
}

@end
