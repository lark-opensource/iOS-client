//
//  HMDNetworkSpeedManagerTests.m
//  HMDNetworkSpeedManagerTests
//
//  Created by bytedance on 2020/8/4.
//  Copyright © 2020 bytedance. All rights reserved.
//

#include <pthread.h>
#include <objc/objc.h>
#include <objc/runtime.h>
#include <objc/message.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "HMDMacro.h"
#import "HMDSwizzle.h"
#import "HMDDynamicCall.h"
#import "HMDNetworkSpeedManager.h"

// heimdallr network speed test associated object
@interface HMDNSTAO: NSObject
@end @implementation HMDNSTAO {
    dispatch_block_t _block;
}

+ (instancetype)objectWithBlock:(dispatch_block_t)block {
    return [[HMDNSTAO alloc] initWithBlock:block];
}

- (instancetype)initWithBlock:(dispatch_block_t)block {
    if(self = [super init]) {
        _block = block;
    }
    return self;
}

- (void)dealloc {
    if(_block) _block();
}

@end

@interface HMDNetworkSpeedManagerTests : XCTestCase

@end

@implementation HMDNetworkSpeedManagerTests {
    HMDNetworkSpeedManager * _manager1;
    HMDNetworkSpeedManager * _manager2;
    HMDNetworkSpeedManager * _manager3;
    HMDNetworkSpeedManager * _manager4;
    HMDNetworkSpeedManager * _manager5;
}

+ (void)setUp    {
    HMD_mockClassTreeForInstanceMethod(HMDNetworkSpeedManager, timerCallback, ^(id thisSelf){
        
        XCTestExpectation *expectation = objc_getAssociatedObject(thisSelf, (void *)0x12345);
        if(expectation != nil) {
            objc_setAssociatedObject(thisSelf, (void *)0x12345, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [expectation fulfill];
        }
        
        XCTAssert(pthread_main_np() == 0);
        DC_OB(thisSelf, MOCK_timerCallback);
    });
}

+ (void)tearDown { /* 在所有测试后调用一次 */ }
- (void)setUp    { /* 在每次 -[ test_xxx] 方法前调用 */ }
- (void)tearDown { /* 在每次 -[ test_xxx] 方法后调用 */ }

- (void)tools_used_when_test {
    // Expectation
    XCTestExpectation *expectation = [self expectationWithDescription:@"description"];
    [expectation fulfill];
    [self waitForExpectationsWithTimeout:3 handler:nil];
    
    // Assert
    XCTAssert(nil, @"NSLog format:%@", nil);
}

- (void)testNetworkSpeedDataValid {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"testNetworkSpeedDataValid"];
    
    [HMDNetworkSpeedManager averageSpeedOverTimeDuration:3.0
                                       withBlockNoRepeat:^(HMDNetworkSpeedData * _Nonnull data) {
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:6.0 handler:nil];
}

- (void)testNetworkSpeedManagerDealloc {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"testNetworkSpeedManagerDealloc 1"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"testNetworkSpeedManagerDealloc 2"];
    
    _manager1 = [[HMDNetworkSpeedManager alloc] initWithInterval:0.5
                                             intendedAverageTime:2.0
                                                          repeat:YES];
    
    __weak typeof(self) weakSelf = self;
    
    @autoreleasepool {
        [_manager1 addRegisterWithBlock:^(HMDNetworkSpeedData * _Nonnull manager) {
            
            __strong typeof(self) strongSelf = weakSelf;
            
            XCTAssert(pthread_main_np() != 0);
            static int times = 0;
            if(times++ == 5) {
                strongSelf->_manager1 = nil;
                [expectation1 fulfill];
                fprintf(stdout, "expectation1 fulfill");
            }
        }];
        
        objc_setAssociatedObject([self getManagerTimer:_manager1], @selector(new), [HMDNSTAO objectWithBlock:^{
            [expectation2 fulfill];
            fprintf(stdout, "expectation2 fulfill");
        }], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    [self waitForExpectationsWithTimeout:8 handler:nil];
}

- (void)testCalculateNotInMainThread {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"testCalculateNotInMainThread 3"];
    
    _manager2 = [[HMDNetworkSpeedManager alloc] initWithInterval:0.5
                                             intendedAverageTime:2.0
                                                          repeat:YES];
    
    __weak typeof(self) weakSelf = self;
    
    @autoreleasepool {
        objc_setAssociatedObject(_manager2, (void *)0x12345, expectation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        [_manager2 addRegisterWithBlock:^(HMDNetworkSpeedData * _Nonnull manager) {
            
            __strong typeof(self) strongSelf = weakSelf;
            
            XCTAssert(pthread_main_np() != 0);
            static int times = 0;
            if(times++ == 2) {
                strongSelf->_manager2 = nil;
            }
        }];
    }
    
    [self waitForExpectationsWithTimeout:8 handler:nil];
}

- (void)setManager:(HMDNetworkSpeedManager *)manager timer:(dispatch_source_t)timer {
    Ivar ivar = class_getInstanceVariable(HMDNetworkSpeedManager.class, "_timer");
    if(ivar == nil) DEBUG_RETURN_NONE;
    object_setIvar(manager, ivar, timer);
}

- (dispatch_source_t)getManagerTimer:(HMDNetworkSpeedManager *)manager {
    Ivar ivar = class_getInstanceVariable(HMDNetworkSpeedManager.class, "_timer");
    if(ivar == nil) DEBUG_RETURN(nil);
    return object_getIvar(manager, ivar);
}

@end
