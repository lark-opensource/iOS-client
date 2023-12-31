//
//  HMDOTranceTest.m
//  Pods
//
//  Created by liuhan on 2021/10/18.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "HMDOTTrace.h"
#import "HMDOTManager+HMDUnitTest.h"

@interface HMDOTTrace (HMDUnitTest)

@property (nonatomic, assign, readwrite) long long startTimestamp;
@property (nonatomic, assign, readwrite) long long finishTimestamp;
@property (atomic, copy, readwrite) NSDictionary<NSString*, NSString*> *tags;
@property (nonatomic, strong, readwrite) NSMutableArray <HMDOTSpan *>*cachedSpans;

@end



@interface HMDOTranceTest : XCTestCase

+ (long long) transform:(NSDate *)date;

@end


@implementation HMDOTranceTest

//transform date into ms
+ (long long)transform:(NSDate *)date {
    long long res = (long long)(1000 * [date timeIntervalSince1970]);
    return res;
}

+ (void)tearDown {
    [super tearDown];
    OTManagerMock = nil;
}

- (void)setUp {
    if (OTManagerMock == nil) {
        OTManagerMock = OCMPartialMock([HMDOTManager sharedInstance]);
        OCMStub(OTManagerMock.isValid).andReturn(TRUE);
        OCMStub(OTManagerMock.hasStopped).andReturn(FALSE);
    }
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}


-(void)test_startTrace_validName {
    //give valid name
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:@"validCase"];
    //confirm method insertTrace is called
    OCMVerify([OTManagerMock insertTrace:[OCMArg any]]);
    //confirm generating trace succeeds.
    XCTAssertNotNil(testTrace, @"HMDOTrace: failed to startTrace with valid traceName, default date and default insertMode");
    // check default insertMode
    XCTAssertEqual(testTrace.insertMode, HMDOTTraceInsertModeEverySpanStart,  @"HMDOTrace: Default should be HMDOTTraceInsertModeEverySpanStart.");
    
    [testTrace finish];
}

-(void)test_startTrace_nilName {
    //give nil name
    HMDOTTrace *testTrace;
    //confirm method insertTrace is called
//    OCMVerify([OTManagerMock insertTrace:[OCMArg any]]);
    //confirm generating trace succeeds.
    XCTAssertThrows(testTrace = [HMDOTTrace startTrace:nil],  @"HMDOTrace: failed to startTrace with nil traceName, default date and default insertMode");
    
    [testTrace finish];
}

-(void)test_startTrace_WithValidDate {
    NSString *traceName = @"validCase";
    NSDate *traceDate = [NSDate dateWithTimeIntervalSinceNow:-24 * 60 * 60];
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:traceName startDate:traceDate];
    XCTAssertNotNil(testTrace, @"HMDOTrace: failed to startTrace with valid traceName, valid date and default insertMode");
    XCTAssertEqual(testTrace.insertMode, HMDOTTraceInsertModeEverySpanStart, @"HMDOTrace: Default insertMode should be HMDOTTraceInsertModeEverySpanStart");
    XCTAssertEqual(testTrace.startTimestamp, [HMDOTranceTest transform:traceDate], @"HMDOTrace: StartTime of trace enable is not assigned time");
    [testTrace finish];
}

-(void)test_startTrace_WithNilDate {
    NSString *traceName = @"nil_startTime";
    long long beforTimeStamp = [HMDOTranceTest transform:[NSDate date]];
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:traceName startDate:nil];
    long long afterTimeStamp = [HMDOTranceTest transform:[NSDate date]];
    XCTAssertTrue(beforTimeStamp < testTrace.startTimestamp < afterTimeStamp, @"HMDOTrace: StartTime of trace generating with nil date is error");
    [testTrace finish];
}

- (void)test_startTrace_startDate_insertMode {
    //参数依赖_给定合理tracename/date/mode信息
    NSString* traceName = @"valid_trace";
    NSDate* startDate = [NSDate date];
    NSInteger insertMode = HMDOTTraceInsertModeAllSpanBatch;
    
    //行为
    HMDOTTrace* testTrace = [HMDOTTrace startTrace:traceName startDate:startDate insertMode:insertMode];
    
    //检验
    XCTAssertNotNil(testTrace, @"HMDOTTrace: failed to startTrace with assigned insertMode");
    XCTAssertEqual(testTrace.insertMode, HMDOTTraceInsertModeAllSpanBatch, @"HMDOTTrac: Assigned insertMode Error");
    XCTAssertTrue(testTrace.needCache, @"HMDOTTrace: Variable needCache should be False under HMDOTTraceInsertModeEverySpanStart");
    
    //inValid insertMode
    traceName = @"invalid_insertMode_trace";
    startDate = [NSDate date];
    
    XCTAssertThrows([HMDOTTrace startTrace:traceName startDate:startDate insertMode:6], @"HMDOTTrace: Trace can not be created with invalid insertMode");
    [testTrace finish];
}

-(void) test_resetTraceStartDate {
    NSDate *startDate = [NSDate date];
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:@"resertStartDate" startDate:startDate];
    NSDate *newStartDate = [NSDate dateWithTimeIntervalSinceNow:-24 * 60 * 60];
    
    [testTrace resetTraceStartDate:newStartDate];
    
    XCTAssertEqual(testTrace.startTimestamp, [HMDOTranceTest transform:newStartDate], @"HMDOTTrace: Reserting start time with valid param faild");
    
    [testTrace finish];
}

-(void) test_resetTraceStartDate_withNilDate {
    NSDate *startDate = [NSDate date];
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:@"resertStartDateWithNilDate" startDate:startDate];
    
    [testTrace resetTraceStartDate:nil];
    
    XCTAssertEqual(testTrace.startTimestamp, [HMDOTranceTest transform:startDate], @"HMDOTTrace: StartTime should stay the same after reserting startTime with nil date");
    
    [testTrace finish];
}

-(void) test_resetTraceStartDate_withFinishedTrace {
    NSDate *startDate = [NSDate date];
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:@"resertStartDateWithNilDate" startDate:startDate];
    NSDate *newStartDate = [NSDate dateWithTimeIntervalSinceNow:-24 * 60 * 60];
    
    [testTrace finish];
    XCTAssertTrue(testTrace.isFinished == 1, @"HMDOTTrace: Trace finished manually is still running");
    
    [testTrace resetTraceStartDate:newStartDate];
    
    XCTAssertEqual(testTrace.startTimestamp, [HMDOTranceTest transform:startDate], @"HMDOTTrace: StartTime should stay the same after reserting startTime with finished trace");
}

-(void)test_finish {
    //Given trace that is running
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:@"testTrace"];
    
    [testTrace finish];
    
    //Confirm replaceTrace is called
    OCMVerify([OTManagerMock replaceTrace:[OCMArg any]]);
    XCTAssertTrue(testTrace.isFinished == 1, @"HMDOTTrace: Failed to finish trace");
}

-(void)test_finish_withInsertModeSpanBatch {
    //Given trace that is running
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:@"testTrace"];
    
    [testTrace finish];
    
    //Confirm replaceTrace is called
    OCMVerify([OTManagerMock insertTrace:[OCMArg any]]);
    XCTAssertTrue(testTrace.isFinished == 1, @"HMDOTTrace: Failed to finish trace");
}

-(void)test_finish_withFinishedTrace {
    //Given trace that is running
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:@"testTrace"];
    [testTrace finish];
    NSDate *finishTime = [NSDate dateWithTimeIntervalSinceNow:60];
    
    [testTrace finishWithDate:finishTime];
    
    XCTAssertNotEqual(testTrace.finishTimestamp, [HMDOTranceTest transform:finishTime], @"HMDOTTrace: Update finishTimeStamp of finished trace unexpectly");
}


-(void)test_finishWithDate {
    //given valid trace and valid finishTime
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:@"testTrace"];
    XCTAssertTrue(testTrace.isFinished == 0, @"HMDOTTrace: given trace has finished");
    NSDate *finishTime = [NSDate date];
    
    [testTrace finishWithDate:finishTime];
    
    XCTAssertTrue(testTrace.isFinished == 1, @"HMDOTTrace: Failed to finish trace");
    XCTAssertEqual(testTrace.finishTimestamp, [HMDOTranceTest transform:finishTime], @"HMDOTTrace: Failed to finish trace with assigned finishTime");
}

-(void)test_finishWithNilDate {
    //given valid trace and nil finishTime
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:@"testTrace"];
    XCTAssertTrue(testTrace.isFinished == 0, @"HMDOTTrace: given trace has finished");
    
    long long beforeFinishTime = [HMDOTranceTest transform:[NSDate date]];
    [testTrace finishWithDate:nil];
    long long afterFinishTime = [HMDOTranceTest transform:[NSDate date]];
    
    XCTAssertTrue(testTrace.isFinished == 1, @"HMDOTTrace: Failed to finish trace");
    XCTAssertTrue(beforeFinishTime < testTrace.finishTimestamp < afterFinishTime, @"HMDOTTrace: FinishTime of trace generating with nil date is error");
}

- (void)test_finishWithInValidDate {
    //given valid trace and valid finishTime
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:@"testTrace"];
    XCTAssertTrue(testTrace.isFinished == 0, @"HMDOTTrace: given trace has finished");
    NSDate *finishTime = [NSDate dateWithTimeIntervalSinceNow:-24 * 60 * 60];
    
    
    XCTAssertThrows([testTrace finishWithDate:finishTime], @"HMDOTTrace: Given trace finished unexpectedly");
    [testTrace finish];
}

- (void)test_setTag_withValidKey_andValidValue {
    //Given valid trace key and value
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:@"testTrace"];
    NSString *tag = @"testTag";
    NSString *value = @"testValue";
    
    [testTrace setTag:tag value:value];
    
    XCTAssertTrue([[testTrace.tags allKeys] containsObject:tag], @"HMDOTTrace: Failed to set tag & value");
    XCTAssertEqual([testTrace.tags objectForKey:tag], value, @"HMDOTTrace: Failed to set tag & value");
    [testTrace finish];
}

- (void)test_setTag_withValidKey_andNilValue {
    //Given valid trace key and value
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:@"testTrace"];
    NSString *tag = @"testTag";
    
    [testTrace setTag:tag value:nil];
    
    XCTAssertFalse([[testTrace.tags allKeys] containsObject:tag], @"HMDOTTrace: Nil value should not be added");
    
    [testTrace finish];
}

- (void)test_setTag_withNilKey_andNilValue {
    //Given valid trace key and value
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:@"testTrace"];
    
    NSDictionary *oriDic = testTrace.tags;
    [testTrace setTag:nil value:nil];
    
    XCTAssertEqual(oriDic, testTrace.tags, @"HMDOTTrace: Nil value and nil tag should not be added");
    
    [testTrace finish];
}

- (void)test_abandonCurrentTrace {
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:@"testTrace"];
    
    [testTrace abandonCurrentTrace];
    
    OCMVerify([OTManagerMock cleanupCachedTrace:testTrace]);
    XCTAssertTrue(testTrace.isAbandoned, @"HMDOTTrace: Failed to abandon trace with default insertMode");
    XCTAssertEqual(testTrace.cachedSpans.count, 0, @"HMDOTTrace: Failed to clean up cachedSpan when abondaning trace with default insertMode");
    
    [testTrace finish];
    }

- (void)test_abandonCurrentTrace_spanStartMode {
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:@"testTrace" startDate:[NSDate date] insertMode:HMDOTTraceInsertModeAllSpanBatch];
    
    [testTrace abandonCurrentTrace];
    
    OCMVerify([OTManagerMock cleanupCachedTrace:testTrace]);
    XCTAssertTrue(testTrace.isAbandoned, @"HMDOTTrace: Failed to abandon trace with HMDOTTraceInsertModeAllSpanBatch");
    XCTAssertEqual(testTrace.cachedSpans.count, 0, @"HMDOTTrace: Failed to clean up cachedSpan when abondaning trace with HMDOTTraceInsertModeAllSpanBatch");
    
    [testTrace finish];
    }

- (void)test_abandonCurrentTrace_spanFinishMode {
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:@"testTrace" startDate:[NSDate date] insertMode:HMDOTTraceInsertModeEverySpanFinish];
    
    [testTrace abandonCurrentTrace];
    
    OCMVerify([OTManagerMock cleanupCachedTrace:testTrace]);
    XCTAssertTrue(testTrace.isAbandoned, @"HMDOTTrace: Failed to abandon trace with HMDOTTraceInsertModeEverySpanFinish");
    XCTAssertEqual(testTrace.cachedSpans.count, 0, @"HMDOTTrace: Failed to clean up cachedSpan when abondaning trace with HMDOTTraceInsertModeEverySpanFinish");
    
    [testTrace finish];
    }

@end
