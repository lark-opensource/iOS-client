//
//  HMDOTBridgeTest.m
//  Pods
//
//  Created by liuhan on 2021/10/28.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <Heimdallr/HMDOTBridge.h>
#import <Heimdallr/HMDOTTrace.h>

@interface HMDOTBridge (HMDUnitTest)

@property (atomic, assign) BOOL enableBinding;
@property (nonatomic, strong) NSMutableDictionary *cachedTraces;

- (instancetype)init;
- (void)appendSpans:(NSArray<HMDOTSpan *> *)spans forTraceID:(NSString *)traceID;

@end

@interface HMDOTBridgeTest : XCTestCase

@property HMDOTBridge *OTBridgeMock;

@end


@implementation HMDOTBridgeTest

- (void)mockShareInstance {
    id OTBridgeMock = OCMClassMock([HMDOTBridge class]);
    self.OTBridgeMock = [[HMDOTBridge alloc] init];
    OCMStub([[OTBridgeMock classMethod] sharedInstance]).andReturn(self.OTBridgeMock);
}

- (void)setUp {
    [self mockShareInstance];
    self.OTBridgeMock = OCMPartialMock([HMDOTBridge sharedInstance]);
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    self.OTBridgeMock = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)test_enableTraceBinding {
    [self.OTBridgeMock enableTraceBinding:TRUE];
    
    XCTAssertTrue(self.OTBridgeMock.enableBinding, @"HMDOTBridge: Failed to disable trace binding");
}

- (void)test_enableTraceBinding_false {
    [self.OTBridgeMock enableTraceBinding:FALSE];
    
    XCTAssertFalse(self.OTBridgeMock.enableBinding, @"HMDOTBridge: Failed to disable trace binding");
}

- (void)test_registerTrace_success {
    //Arrange
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:@"testTrace"];
    [self.OTBridgeMock enableTraceBinding:TRUE];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Register trace time out!"];
    //Act
    [self.OTBridgeMock registerTrace:testTrace forTraceID:testTrace.traceID];
    //Assert
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        XCTAssertTrue([[self.OTBridgeMock.cachedTraces allKeys] containsObject:testTrace.traceID], @"HMDOTBridge: Failed to register th he assigned trace to chachedTraces according to traceID");
        XCTAssertTrue([[self.OTBridgeMock.cachedTraces objectForKey:testTrace.traceID] isEqual:testTrace], @"HMDOTBridge: Failed to register th he assigned trace to chachedTraces according to the trace");
        
        [testTrace finish];
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:3 handler:nil];
}

- (void)test_registerTrace_withUnableBinding {
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:@"testTrace"];
    
    [self.OTBridgeMock registerTrace:testTrace forTraceID:testTrace.traceID];
    
    sleep(1);
    XCTAssertFalse([[self.OTBridgeMock.cachedTraces allKeys] containsObject:testTrace.traceID], @"HMDOTBridge: Trace should not cached when enableBinding is false");
    
    [testTrace finish];
}

- (void)test_test_registerTrace_withNilTrace {
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:@"testTrace"];
    
    [self.OTBridgeMock registerTrace:nil forTraceID:testTrace.traceID];
    
    sleep(1);
    XCTAssertFalse([[self.OTBridgeMock.cachedTraces allKeys] containsObject:testTrace.traceID], @"HMDOTBridge: TraceID should not be cached when trace is nil");
    
    [testTrace finish];
}

- (void)test_test_registerTrace_withNilTraceID {
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:@"testTrace"];
    
    [self.OTBridgeMock registerTrace:testTrace forTraceID:nil];
    
    sleep(1);
    XCTAssertFalse([[self.OTBridgeMock.cachedTraces allValues] containsObject:testTrace], @"HMDOTBridge: Trace should not be cached when traceID is nil");
    
    [testTrace finish];
}

- (void)test_removeTraceID {
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:@"testTrace"];
    [self.OTBridgeMock enableTraceBinding:TRUE];
    [self.OTBridgeMock registerTrace:testTrace forTraceID:testTrace.traceID];
    
    [self.OTBridgeMock removeTraceID:testTrace.traceID];
    
    sleep(1);
    XCTAssertFalse([[self.OTBridgeMock.cachedTraces allKeys] containsObject:testTrace.traceID], @"HMDOTBridge: Failed to register th he assigned trace to chachedTraces according to traceID");
    
    [testTrace finish];
}

- (void)test_removeTraceID_withUnableTraceBinding {
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:@"testTrace"];
    [self.OTBridgeMock enableTraceBinding:TRUE];
    [self.OTBridgeMock registerTrace:testTrace forTraceID:testTrace.traceID];
    [self.OTBridgeMock enableTraceBinding:FALSE];
    
    [self.OTBridgeMock removeTraceID:testTrace.traceID];
    
    sleep(1);
    XCTAssertTrue([[self.OTBridgeMock.cachedTraces allKeys] containsObject:testTrace.traceID], @"Trace should not be removed when enableBinding is false");
    
    [testTrace finish];
}

- (void)test_removeTraceID_withNilID {
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:@"testTrace"];
    [self.OTBridgeMock enableTraceBinding:TRUE];
    [self.OTBridgeMock registerTrace:testTrace forTraceID:testTrace.traceID];
    
    [self.OTBridgeMock removeTraceID:nil];
    
    sleep(1);
    XCTAssertTrue([[self.OTBridgeMock.cachedTraces allKeys] containsObject:testTrace.traceID], @"Trace should not be removed when given a nil traceID");
    
    [testTrace finish];
}

- (void)test_traceByTraceID {
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:@"testTrace"];
    [self.OTBridgeMock enableTraceBinding:TRUE];
    [self.OTBridgeMock registerTrace:testTrace forTraceID:testTrace.traceID];

    HMDOTTrace *trace = [self.OTBridgeMock traceByTraceID:testTrace.traceID];
    
    sleep(1);
    XCTAssertTrue([trace isEqual:testTrace], @"HMDOTBridge: Failed to register th he assigned trace to chachedTraces according to the trace");
        
    [testTrace finish];
}

- (void)test_traceByErrTraceID {
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:@"testTrace"];
    [self.OTBridgeMock enableTraceBinding:TRUE];
    [self.OTBridgeMock registerTrace:testTrace forTraceID:testTrace.traceID];
    [self.OTBridgeMock removeTraceID:testTrace.traceID];
    
    HMDOTTrace *trace = [self.OTBridgeMock traceByTraceID:testTrace.traceID];
    
    sleep(1);
    XCTAssertNil(trace, @"HMDOTBridge: The method should return nil with a unexpected param traceID");
        
    [testTrace finish];
}

- (void)test_traceByNilTraceID {
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:@"testTrace"];
    [self.OTBridgeMock enableTraceBinding:TRUE];
    [self.OTBridgeMock registerTrace:testTrace forTraceID:testTrace.traceID];
    
    HMDOTTrace *trace = [self.OTBridgeMock traceByTraceID:nil];
    
    sleep(1);
    XCTAssertNil(trace, @"HMDOTBridge: The method should return nil with a nil traceID");
        
    [testTrace finish];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
