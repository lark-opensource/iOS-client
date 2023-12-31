//
//  HMDOTSpanTest.m
//  Pods
//
//  Created by liuhan on 2021/10/14.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <OCMock/OCPartialMockObject.h>
#import "HMDOTSpan.h"
#import "HMDOTTrace.h"
#import "HMDOTManager+HMDUnitTest.h"

#define stopMocking(obj) [OCPartialMockObject stopMocking:obj]

@interface HMDOTSpan (HMDUnitTest)

@property (nonatomic, copy) NSString *operationName;//一次span的名称，多个span之间可以重复
@property (nonatomic, copy, readwrite) NSString *traceID;//一次完整场景的id，在所有span之间共享
@property (nonatomic, copy, readwrite) NSString *spanID;//唯一的id，随机数
@property (nonatomic, copy) NSString *parentID;//多层次之间的父节点的spanID，根节点为空
@property (nonatomic, assign) long long startTimestamp;
@property (nonatomic, assign) long long finishTimestamp;
@property (atomic, copy) NSArray<NSDictionary *> *logs;
@property (atomic, copy) NSDictionary<NSString*, NSString*> *tags;
@property (nonatomic, assign, readwrite) NSUInteger isFinished;
@property (nonatomic, copy) NSString *referenceID;//表示当前span逻辑上的前序span的spanID

@end

@interface HMDOTSpanTest : XCTestCase

@property HMDOTTrace *OTTrace;

+ (long long) transform:(NSDate *)date;

@end

@implementation HMDOTSpanTest

//transform date into ms
+ (long long)transform:(NSDate *)date {
    long long res = (long long)(1000 * [date timeIntervalSince1970]);
    return res;
}

+ (void)tearDown {
    OTManagerMock = nil;
    [super tearDown];
}

- (void)setUp {
    self.OTTrace = [HMDOTTrace startTrace:@"testTrace"];
    if (OTManagerMock == nil) {
        OTManagerMock = OCMPartialMock([HMDOTManager sharedInstance]);
        OCMStub(OTManagerMock.isValid).andReturn(TRUE);
        OCMStub(OTManagerMock.hasStopped).andReturn(FALSE);
    }
    // Put setup code here. This method is called before thinvocation of each test method in the class.
}

- (void)tearDown {
    [self.OTTrace finish];
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)test_startSpanOfTrace_operationName {
    
    NSString *spanName =@"testSpan";
    
    HMDOTSpan *testSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:spanName];
    
    XCTAssertNotNil(testSpan, @"HMDOTSpan: Failed to creat a span");
    XCTAssertEqual(testSpan.operationName, spanName, @"HMDOTSpan: operationName of created span is wrong");
    XCTAssertEqual(testSpan.traceID, self.OTTrace.traceID,  @"HMDOTSpan: traceID of created span is wrong");
    
    [testSpan finish];
//    [OTManagerMock stopMocking];
}

- (void)test_startSpanOfNilTrace_operationName {
    NSString *spanName = @"testSpan";

    XCTAssertThrows([HMDOTSpan startSpanOfTrace:nil operationName:spanName], @"HMDOTSpan: Span with a nil trace should not be created");
}

- (void)test_startSpanOfFinishedTrace_operationName {
    HMDOTTrace *trace = [HMDOTTrace startTrace:@"testTrace"];
    [trace finish];
    XCTAssertThrows([HMDOTSpan startSpanOfTrace:trace operationName:@"testSpan"], @"HMDOTSpan: Span with a nil name should not be created");
}

- (void)test_startSpanOfTrace_operationName_spanStartDate {
    NSString *spanName = @"testSpan";
    NSDate *spanDate = [NSDate dateWithTimeIntervalSinceNow:-60];
    
    HMDOTSpan *testSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:spanName spanStartDate:spanDate];
    
    XCTAssertNotNil(testSpan, @"HMDOTSpan: Failed to start a span with assigned name and date");
    XCTAssertEqual(testSpan.startTimestamp, [HMDOTSpanTest transform:spanDate], @"HMDOTSpan: Failed to start a span with assigned name and date");
    
    [testSpan finish];
}

- (void)test_startSpanOfTrace_operationName_nilSpanStartDate {
    NSString *spanName = @"testSpan";
    long long beforeStartTime = [HMDOTSpanTest transform:[NSDate date]];
    
    HMDOTSpan *testSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:spanName spanStartDate:nil];
    long long afterStartTime = [HMDOTSpanTest transform:[NSDate date]];
    
    XCTAssertNotNil(testSpan, @"HMDOTSpan: Failed to start a span without assigned date");
    XCTAssertTrue(beforeStartTime < testSpan.startTimestamp < afterStartTime,  @"HMDOTSpan: Generate wrong start time of span without assigned date");
    
    [testSpan finish];
}

- (void)test_startSpan_childOfSpan {
    HMDOTSpan *parentSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:@"parentSpan"];
    NSString *spanName = @"childSpan";
    
    HMDOTSpan *childSpan = [HMDOTSpan startSpan:spanName childOf:parentSpan];
    
    XCTAssertNotNil(childSpan, @"HMDOTSpan: Failed to start a child span");
    XCTAssertEqual(childSpan.operationName, spanName, @"HMDOTSpan: Generating wrong operationName of child span");
    XCTAssertEqual(childSpan.parentID, parentSpan.spanID, @"HMDOTSpan: The parentID of childSpan is not equal to the spanID of the parentID");
    
    [parentSpan finish];
    [childSpan finish];
}

- (void)test_startSpan_childOfNilSpan {
    XCTAssertThrows([HMDOTSpan startSpan:@"childSpan" childOf:nil], @"HMDOTSpan: Child span should not be started when parent span is nil");
}

//- (void)test_startSpan_childOfFinishedSpan {
//    HMDOTSpan *parentSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:@"parentSpan"];
//
//    [parentSpan finish];
//
//    XCTAssertThrows([HMDOTSpan startSpan:@"childSpan" childOf:parentSpan], @"HMDOTSpan: Child span should not be started when parent span has finished");
//}

- (void)test_startSpan_childOfSpanWithFinishedTrace {
    HMDOTTrace *trace = [HMDOTTrace startTrace:@"testTrace"];
    HMDOTSpan *parentSpan = [HMDOTSpan startSpanOfTrace:trace operationName:@"parentSpan"];
    
    [parentSpan.trace finish];
    
    XCTAssertThrows([HMDOTSpan startSpan:@"childSpan" childOf:parentSpan], @"HMDOTSpan: Child span should not be started when parent's trace has finished");
}

- (void)test_startSpan_childOfParent_withStartDate {
    HMDOTSpan *parentSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:@"parentSpan"];
    NSString *spanName = @"childSpan";
    NSDate *spanDate = [NSDate date];
    HMDOTSpan *childSpan = [HMDOTSpan startSpan:spanName childOf:parentSpan spanStartDate:spanDate];
    
    XCTAssertNotNil(childSpan, @"HMDOTSpan:Start a childSpan with assigned start date failed");
    XCTAssertEqual(childSpan.operationName, spanName, @"HMDOTSpan: Generating a wrong name for the childSpan");
    XCTAssertEqual(childSpan.parentID, parentSpan.spanID, @"HMDOTSpan: The parentID of childSpan is different from the spanID of its parentSpan");
    XCTAssertEqual(childSpan.startTimestamp, [HMDOTSpanTest transform:spanDate], @"HMDOTSpan: The startTimestamp is unmatched to assigned startDate");
    
    [parentSpan finish];
    [childSpan finish];
}

- (void)test_startSpan_childOfParent_withNilStartDate {
    HMDOTSpan *parentSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:@"parentSpan"];
    NSString *spanName = @"childSpan";
    long long beforeSpanStartTimestamp = [HMDOTSpanTest transform:[NSDate date]];
    
    HMDOTSpan *childSpan = [HMDOTSpan startSpan:spanName childOf:parentSpan];
    
    long long afterSpanStartTimestamp = [HMDOTSpanTest transform:[NSDate date]];
    
    XCTAssertNotNil(childSpan, @"HMDOTSpan: Start a childSpan with assigned start date failed");
    XCTAssertEqual(childSpan.operationName, spanName, @"HMDOTSpan: Generating a wrong name for the childSpan");
    XCTAssertEqual(childSpan.parentID, parentSpan.spanID, @"HMDOTSpan: The parentID of childSpan is different from the spanID of its parentSpan");
    XCTAssertTrue(beforeSpanStartTimestamp < childSpan.startTimestamp < afterSpanStartTimestamp, @"HMDOTSpan: The startTimestamp of childSpan without assigned startDate is wrong");
    
    [parentSpan finish];
    [childSpan finish];
}

- (void)test_startSpan_referenceOf {
    HMDOTSpan *referenceSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:@"referenceSpan"];
    NSString *spanName = @"broSpan";
    
    HMDOTSpan *broSpan = [HMDOTSpan startSpan:spanName referenceOf:referenceSpan];
    
    XCTAssertNotNil(broSpan, @"HMDOTSpan: Start a referenceSpan with assigned name failed");
    XCTAssertEqual(broSpan.operationName, spanName, @"HMDOTSpan: The name of the started span is different from the reference span");
    XCTAssertEqual(broSpan.referenceID, referenceSpan.spanID, @"HMDOTSpan: The referenceID of started span is different from the spanID of its reference span");
    XCTAssertEqual(broSpan.parentID, referenceSpan.parentID, @"HMDOTSpan: The parentID of started span is different from the parentID of its reference span");
    [referenceSpan finish];
    [broSpan finish];
}

- (void)test_startSpan_referenceOfNil {
    XCTAssertThrows([HMDOTSpan startSpan:@"nilReferenceSpan" referenceOf:nil], @"HMDOTSpan: Span should not be started with nil reference span");
}

-(void)test_startSpan_referenceOfFinishedTrace {
    HMDOTTrace *trace = [HMDOTTrace startTrace:@"testTrace"];
    HMDOTSpan *referenceSpan = [HMDOTSpan startSpanOfTrace:trace operationName:@"referenceSpan"];
    [trace finish];
    
    XCTAssertThrows([HMDOTSpan startSpan:@"broSpan" referenceOf:referenceSpan], @"HMDOTSpan: Span should not be started with nil trace");
}

- (void)test_logMessage_withfields {
    HMDOTSpan *testSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:@"testSpan"];
    NSString *message = @"testMsg";
    NSDictionary *fields = [NSDictionary dictionaryWithObjectsAndKeys:@"testV1", @"testK1", @"testV2", @"testK2", nil];
    
    [testSpan logMessage:message fields:fields];
    
    __block BOOL isMatch = FALSE;
    [testSpan.logs enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[obj objectForKey:@"message"] isEqual:message] &&
            [[obj objectForKey:@"fields"] isEqual:fields]) {
            isMatch = TRUE;
            *stop = YES;
        }
    }];
    
    XCTAssertNotNil(testSpan.logs, @"HMDOTSpan: Failed to add valid message and fields to logs of span");
    XCTAssertTrue(isMatch, @"HMDOTSpan: Logs of span do not contain assigned message and fields");
    
    [testSpan finish];
}

- (void)test_logMessage_withNilfields {
    HMDOTSpan *testSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:@"testSpan"];
    NSString *message = @"testMsg_nilFields";
    
    [testSpan logMessage:message fields:nil];
    
    __block BOOL isMatch = FALSE;
    [testSpan.logs enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[obj allKeys] containsObject:@"message"] &&
            ![[obj allKeys] containsObject:@"fields"]) {
            isMatch = TRUE;
            *stop = YES;
        }
    }];
    XCTAssertTrue(isMatch, @"HMDOTSpan: Nil fields should not be addeed to logs");
    
    [testSpan finish];
}

- (void)test_nilLogMessage_withfields {
    HMDOTSpan *testSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:@"testSpan"];
    NSDictionary *fields = [NSDictionary dictionaryWithObjectsAndKeys:@"testV1", @"testK1", @"testV2", @"testK2", nil];
    
    [testSpan logMessage:nil fields:fields];
    
    __block BOOL isMatch = FALSE;
    [testSpan.logs enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![[obj allKeys] containsObject:@"message"] &&
            [[obj allKeys] containsObject:@"fields"]) {
            isMatch = TRUE;
            *stop = YES;
        }
    }];
    XCTAssertTrue(isMatch, @"HMDOTSpan: Nil message should not be addeed to logs");
    
    [testSpan finish];
}

- (void)test_nilLogMessage_withNilfields {
    HMDOTSpan *testSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:@"testSpan"];
    
    [testSpan logMessage:nil fields:nil];
    
    XCTAssertEqual(testSpan.logs.count, 0, @"HMDOTSpan: Nil message and nil fields should not be addeed to logs");
    [testSpan finish];
}

- (void)test_LogMessage_withInValidfields {
    HMDOTSpan *testSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:@"testSpan"];
    NSString *message = @"testMsg_inValidFields";
    NSDictionary *fields = @{@"anObject" : @"someObject", @"magicNumber" : @42};
    
    XCTAssertThrows([testSpan logMessage:message fields:fields], @"HMDOTSpan: Both keys and values shoule be NSString.");
    
    [testSpan finish];
}

- (void)test_logError {
    HMDOTSpan *testSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:@"testSpan"];
    NSError *error = [[NSError alloc] initWithDomain:@"testError" code:0 userInfo:nil];
    NSString *errorMsg = [NSString stringWithFormat:@"error_code:%ld, error_message:%@", (long)error.code, error.description];
    
    [testSpan logError:error];
    
    XCTAssertTrue([[testSpan.tags allKeys] containsObject:@"error"], @"HMDOTSpan: Failed to add an error tag to tags");
    XCTAssertTrue([[testSpan.tags objectForKey:@"error"] isEqual:errorMsg], @"HMDOTSpan: Error message generated is unmatched to assigned NSError");
    XCTAssertEqual(testSpan.trace.hasError, 1, @"HMDOTSpan: span.trace.hasError should be 1 after adding a error tag to tags");
    
    [testSpan finish];
}

-(void)test_logNilError {
    HMDOTSpan *testSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:@"testSpan"];
    
    [testSpan logError:nil];
    
    XCTAssertThrows(OCMVerify([testSpan setTag:[OCMArg any] value:[OCMArg any]]), @"HMDOTSpan: Method setTag should not be called when error is nil");
    
    [testSpan finish];
}

- (void)test_logErrorWithMessage {
    HMDOTSpan *testSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:@"testSpan"];
    NSString *errMsg = @"testErrorMesage";
    
    [testSpan logErrorWithMessage:errMsg];
    
    XCTAssertTrue([[testSpan.tags allKeys] containsObject:@"error"], @"HMDOTSpan: Failed to add an error tag to tags");
    XCTAssertEqual([testSpan.tags objectForKey:@"error"], errMsg, @"HMDOTSpan: Error message generated is unmatched to assigned NSError");
    XCTAssertEqual(testSpan.trace.hasError, 1, @"HMDOTSpan: span.trace.hasError should be 1 after adding a error tag to tags");
    
    [testSpan finish];
}

- (void)test_logErrorWithNilMessage {
    HMDOTSpan *testSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:@"testSpan"];
    
    [testSpan logErrorWithMessage:nil];
    
    XCTAssertThrows(OCMVerify([testSpan setTag:[OCMArg any] value:[OCMArg any]]), @"HMDOTSpan: Method setTag should not be called when error is nil");
    
    [testSpan finish];
}

- (void)test_setTag_withValue {
    HMDOTSpan *testSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:@"testSpan"];
    NSString *testTag = @"testValidTag";
    NSString *testValue = @"testValidValue";
    
    [testSpan setTag:testTag value:testValue];
    
    XCTAssertTrue([[testSpan.tags allKeys] containsObject:testTag], @"HMDOTSpan: Add valid tag and value failed");
    XCTAssertEqual([testSpan.tags objectForKey:testTag], testValue, @"HMDOTSpan: Add valid tag and value failed");
    
    [testSpan finish];
}

- (void)test_setTag_withNilValue {
    HMDOTSpan *testSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:@"testSpan"];
    NSString *testTag = @"testValidTag";
    
    [testSpan setTag:testTag value:nil];
    
    XCTAssertFalse([[testSpan.tags allKeys] containsObject:testTag], @"HMDOTSpan: Tag should not be added with nil value");
    
    [testSpan finish];
}

- (void)test_setNilTag_withValue {
    HMDOTSpan *testSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:@"testSpan"];
    NSInteger count = testSpan.tags.count;
    NSString *testValue = @"testValidValue";
    
    [testSpan setTag:nil value:testValue];
    
    XCTAssertEqual(count, testSpan.tags.count, @"HMDOTSpan: Nil tag should not be added");
    
    [testSpan finish];
}

//- (void)test_setTag_withInValidValue {
//    HMDOTSpan *testSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:@"testSpan"];
//    NSString *testTag = @"testValidTag";
//    NSInteger testValue = 85;
//
//    [testSpan setTag:testTag value:testValue];
//
//
//
//}

- (void)test_setInvalidTag_withValue {
    HMDOTSpan *testSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:@"testSpan"];
    NSString *testTag = @"testValidTag";
    NSString *testValue = @"testValidValue";
    [self.OTTrace setTag:testTag value:testValue];
    
    XCTAssertThrows([testSpan setTag:testTag value:testValue], @"HMDOTSpan: The tag of span should not be the same as that of the span's trace");
    
    [testSpan finish];
}

- (void)test_resetSpanStartDate {
    HMDOTSpan *testSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:@"testSpan"];
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-85];
    
    [testSpan resetSpanStartDate:startDate];
    
    XCTAssertEqual(testSpan.startTimestamp, [HMDOTSpanTest transform:startDate], @"HMDOTSpan: Failed to reset start time of span");
    
    [testSpan finish];
}

- (void)test_resetSpanStartDate_withNilDate {
    NSDate *startDate = [NSDate date];
    HMDOTSpan *testSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:@"testSpan" spanStartDate:startDate];
    
    [testSpan resetSpanStartDate:nil];
    
    XCTAssertEqual(testSpan.startTimestamp, [HMDOTSpanTest transform:startDate], @"HMDOTSpan: Start time should not be changed with nil date");
    
    [testSpan finish];
}

- (void)test_resetSpanStartDate_ofFinishedSpan {
    NSDate *startDate = [NSDate date];
    HMDOTSpan *testSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:@"testSpan" spanStartDate:startDate];
    [testSpan finish];
    NSDate *restartDate = [NSDate dateWithTimeIntervalSinceNow:60];
    
    [testSpan resetSpanStartDate:restartDate];
    
    XCTAssertEqual(testSpan.startTimestamp, [HMDOTSpanTest transform:startDate], @"HMDOTSpan: Start time should not be changed with nil date");
}

- (void)test_finish {
    HMDOTSpan *testSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:@"testSpan"];
    
    [testSpan finish];
    
    XCTAssertTrue(testSpan.isFinished, @"HMDOTSpan: Failed to finish assigned span");
}

- (void)test_finishWithEndDate {
    HMDOTSpan *testSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:@"testSpan"];
    NSDate *finishDate = [NSDate date];
    [testSpan finishWithEndDate:finishDate];
    
//    long long afterFinishTime = [HMDOTSpanTest transform:[NSDate date]];
    XCTAssertTrue(testSpan.isFinished, @"HMDOTSpan: Failed to finish assigned span");
    XCTAssertEqual([HMDOTSpanTest transform:finishDate], testSpan.finishTimestamp, @"HMDOTSpan: The finish time of testSpan is unmatched to assigned finish date");
}

- (void)test_finishWithNilEndDate {
    HMDOTSpan *testSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:@"testSpan"];
    long long beforeFinishTime = [HMDOTSpanTest transform:[NSDate date]];
    [testSpan finishWithEndDate:nil];
    
    long long afterFinishTime = [HMDOTSpanTest transform:[NSDate date]];
    XCTAssertTrue(testSpan.isFinished, @"HMDOTSpan: Failed to finish assigned span");
    XCTAssertTrue(beforeFinishTime < testSpan.finishTimestamp < afterFinishTime, @"HMDOTSpan: FinishTimeStamp is wrong when finishing span with nil finish date");
}

- (void)test_finishWithEndDate_withFinishedTrace {
    HMDOTTrace *testTrace = [HMDOTTrace startTrace:@"testTrace"];
    HMDOTSpan *testSpan = [HMDOTSpan startSpanOfTrace:testTrace operationName:@"testSpan"];
    [testSpan finish];
    [testTrace finish];
    NSDate *finishDate = [NSDate dateWithTimeIntervalSinceNow:85];
    
    XCTAssertTrue(testTrace.isFinished, @"HMDOTSpan: Failed to finish assigned trace");
    XCTAssertThrows([testSpan finishWithEndDate:finishDate], @"HMDOTSpan: Method related to finishing should be called before its trace finished");
}

- (void)test_finishWithEndDate_withFinishedSpan {
    HMDOTSpan *testSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:@"testSpan"];
    NSDate *finishDate = [NSDate date];
    [testSpan finishWithEndDate:finishDate];
    NSDate *reFinishDate = [NSDate dateWithTimeIntervalSinceNow:10];
    
    [testSpan finishWithEndDate:reFinishDate];
    
    XCTAssertTrue(testSpan.isFinished, @"HMDOTSpan: Failed to finish assigned trace");
    XCTAssertEqual(testSpan.finishTimestamp, [HMDOTSpanTest transform:finishDate], @"HMDOTSpan: Finished span shouled not be finish again");
    XCTAssertNotEqual(testSpan.finishTimestamp, [HMDOTSpanTest transform:reFinishDate], @"HMDOTSpan: Finished span shouled not be finish again");
}

- (void)test_finishWithError {
    HMDOTSpan *testSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:@"testSpan"];
    NSError *testErr = [[NSError alloc] initWithDomain:@"testErr" code:0 userInfo:nil];
    NSString *tempValue = [NSString stringWithFormat:@"error_code:%ld, error_message:%@", (long)testErr.code, testErr.description];
    
    [testSpan finishWithError:testErr];
    
    XCTAssertTrue(testSpan.isFinished, @"HMDOTSpan: Failed to finish span with assigned error");
    XCTAssertTrue([[testSpan.tags allKeys] containsObject:@"error"], @"HMDOTSpan: Failed to add error tag when finishing a span with assigned error");
    XCTAssertTrue([[testSpan.tags objectForKey:@"error"] isEqual:tempValue], @"HMDOTSpan: Failed to add error tag and value when finishing a span with assigned error");
}

- (void)test_finishWithErrorMsg {
    HMDOTSpan *testSpan = [HMDOTSpan startSpanOfTrace:self.OTTrace operationName:@"testSpan"];
    NSString *errMsg = @"testErrMsg";
    
    [testSpan finishWithErrorMsg:errMsg];
    
    XCTAssertTrue(testSpan.isFinished, @"HMDOTSpan: Failed to finish span with assigned error");
    XCTAssertTrue([[testSpan.tags allKeys] containsObject:@"error"], @"HMDOTSpan: Failed to add error tag when finishing a span with assigned error");
    XCTAssertTrue([[testSpan.tags objectForKey:@"error"] isEqual:errMsg], @"HMDOTSpan: Failed to add error tag and value when finishing a span with assigned error");
    
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
