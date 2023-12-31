//
//  TestService.m
//  BDTuring_Tests
//
//  Created by bob on 2019/9/18.
//  Copyright © 2019 Bytedance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <BDTuring/BDTuringService.h>
#import <BDTuring/BDTuringServiceCenter.h>
#import <objc/runtime.h>

@interface BDTuringService (Test)

@property (nonatomic, copy) NSString *serviceName;

@end

@implementation BDTuringService(Test)

- (NSString *)serviceName {
    return objc_getAssociatedObject(self, @selector(serviceName));
}

- (void)setServiceName:(NSString *)serviceName {
    objc_setAssociatedObject(self, @selector(serviceName), [serviceName copy], OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

@interface TestService : XCTestCase

@end

@implementation TestService

- (void)setUp {
    [[BDTuringServiceCenter defaultCenter] unregisterAllServices];
}

- (void)testRegistser {
    NSString *appID = @"123";
    NSString *serviceName = @"Test";
    XCTAssertNil([[BDTuringServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);
    BDTuringService *service1 = [[BDTuringService alloc] initWithAppID:appID];
    service1.serviceName = serviceName;
    [service1 registerService];


    XCTAssertNotNil([[BDTuringServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);
    XCTAssertEqualObjects(service1, [[BDTuringServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);
    XCTAssertEqual(service1, [[BDTuringServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);

    BDTuringService *service2 = [[BDTuringService alloc] initWithAppID:appID];
    service2.serviceName = serviceName;
    [[BDTuringServiceCenter defaultCenter] registerService:service2];

    XCTAssertNotNil([[BDTuringServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);
    XCTAssertEqualObjects(service2, [[BDTuringServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);
    XCTAssertEqual(service2, [[BDTuringServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);
    XCTAssertNotEqual(service1, [[BDTuringServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);
    XCTAssertNotEqualObjects(service1, [[BDTuringServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);


    BDTuringService *service4 = [[BDTuringService alloc] initWithAppID:appID];
    BDTuringService *service5 = [[BDTuringService alloc] initWithAppID:@""];
    service5.serviceName = serviceName;
    [[BDTuringServiceCenter defaultCenter] registerService:service4];
    [[BDTuringServiceCenter defaultCenter] registerService:service5];

    [[BDTuringServiceCenter defaultCenter] unregisterAllServices];
    XCTAssertNil([[BDTuringServiceCenter defaultCenter] serviceForName:@"" appID:appID]);
    XCTAssertNil([[BDTuringServiceCenter defaultCenter] serviceForName:serviceName appID:@""]);

    [[BDTuringServiceCenter defaultCenter] registerService:service4];
    [[BDTuringServiceCenter defaultCenter] registerService:service5];
    [[BDTuringServiceCenter defaultCenter] unregisterService:service4];
    [[BDTuringServiceCenter defaultCenter] unregisterService:service5];
    XCTAssertNil([[BDTuringServiceCenter defaultCenter] serviceForName:@"" appID:appID]);
    XCTAssertNil([[BDTuringServiceCenter defaultCenter] serviceForName:serviceName appID:@""]);
}

- (void)testUnregistser {
    NSString *appID = @"123";
    NSString *serviceName = @"Test";
    XCTAssertNil([[BDTuringServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);
    BDTuringService *service1 = [[BDTuringService alloc] initWithAppID:appID];
    service1.serviceName = serviceName;
    [service1 registerService];

    XCTAssertNotNil([[BDTuringServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);
    XCTAssertEqualObjects(service1, [[BDTuringServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);
    XCTAssertEqual(service1, [[BDTuringServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);

    [service1 unregisterService];
    XCTAssertNil([[BDTuringServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);

    [service1 registerService];
    XCTAssertNotNil([[BDTuringServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);
    [[BDTuringServiceCenter defaultCenter] unregisterService:service1];
    XCTAssertNil([[BDTuringServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);

    [service1 registerService];
    XCTAssertNotNil([[BDTuringServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);
    [[BDTuringServiceCenter defaultCenter] unregisterAllServices];
    XCTAssertNil([[BDTuringServiceCenter defaultCenter] serviceForName:serviceName appID:appID]);
}

- (void)testServices {
    NSString *appID = @"123";
    NSString *serviceName = @"Test";
    BDTuringService *service1 = [[BDTuringService alloc] initWithAppID:appID];
    service1.serviceName = serviceName;
    [service1 registerService];

    BDTuringService *service2 = [[BDTuringService alloc] initWithAppID:@"124"];
    service2.serviceName = serviceName;
    [service2 registerService];

    [[BDTuringServiceCenter defaultCenter] unregisterAllServices];
    service1 = [[BDTuringService alloc] initWithAppID:appID];
    service1.serviceName = serviceName;
    [service1 registerService];
    service2 = [[BDTuringService alloc] initWithAppID:appID];
    service2.serviceName = @"133";
    [service2 registerService];

}

@end
