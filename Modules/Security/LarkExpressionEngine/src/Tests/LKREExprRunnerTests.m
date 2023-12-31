//
//  LKREExprRunnerTests.m
//  LKRuleEngine-_Dummy-Unit-_Tests
//
//  Created by bytedance on 2022/2/9.
//

//#import "LKStrategyCenterHelper.h"

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import <LarkExpressionEngine/LKREExprRunner.h>
#import <LarkExpressionEngine/LKREExprEnv.h>
#import <LarkExpressionEngine/LKREExprConst.h>
#import <LarkExpressionEngine/LKRuleEngineReporter.h>
#import <LarkExpressionEngine/LKREChecker.h>

@interface LKREExprEnvTest : LKREExprEnv

@property (nonatomic, strong) NSMutableDictionary *envValues;

@end

@implementation LKREExprEnvTest

- (nullable id)envValueOfKey:(NSString *)key {
    return self.envValues[key];
}

- (void)resetCost {
}

- (CFTimeInterval)cost {
    return 0;
}

@end

@interface LKREExprRunnerTests : XCTestCase

@end

@implementation LKREExprRunnerTests

- (void)setUp {
    id<LKRuleEngineReporter> logger = OCMProtocolMock(@protocol(LKRuleEngineReporter));
    OCMStub([logger log:[OCMArg any] metric:[OCMArg any] category:[OCMArg any]]);
    [LKRuleEngineReporter registerReporter:logger];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)test_LKREExprRunner_register {
    LKREExprRunner *runner = [[LKREExprRunner alloc] init];
    id customFunc = OCMClassMock([LKREFunc class]);
    id customOperator = OCMClassMock([LKREOperator class]);
    
    
    OCMStub([customFunc symbol]).andReturn(@"fakeFunc");
    OCMStub([customOperator symbol]).andReturn(@"fakeOperator");
    OCMStub([customFunc execute:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(@1);
    OCMStub([customOperator execute:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(@2);
    
    [runner registerFunc:customFunc];
    [runner registerOperator:customOperator];
    
    LKREExprResponse *response;
    LKREExprEnv *env = [LKREExprEnv new];
    
    response = [runner execute:@"fakeFunc()" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue([response.result isEqual:@1], @"expression result should be 1");
    
    response = [runner execute:@"fakeOperator" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue([response.result isEqual:@2], @"expression result should be 1");
}

- (void)test_LKREExprRunner_execute_withEnv {
    id runner = [[LKREExprRunner alloc] init];
    LKREExprEnv *env = [LKREExprEnvTest new];
    LKREExprResponse *response;
    id resulttrue = @YES;
    id resultfalse = @NO;
    
    response = [runner execute:@"a.b + 2" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertEqual(response.code, 106, @"LKREEXPRINVALID_EXPRESS");
    
    response = [runner execute:@"\'c\' in {'4', 'c', 'y'}" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue(response.result == resulttrue, @"expression result should be true");
    
    response = [runner execute:@"\"locationSDK\"  in [entryDataTypes] && [entryToken] in {\"LKUGLocationInitSettings\", \"init\"}" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertEqual(response.code, 0, @"expression is valiable");
    XCTAssertTrue([LKREChecker isLKREParamMissing:response.result] == true, @"expression result should be true");
    
    response = [runner execute:@"1 *   + 2 == 3" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertEqual(response.code, 105 ,@"execute:withEnv: | Empty param for operator *");

    response = [runner execute:@"'123" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertEqual(response.code, 107, @"expression is invalid");

    response = [runner execute:@"123 || jj || 12" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertEqual(response.code, 0, @"expression is valiable");
    XCTAssertTrue(response.result == resulttrue, @"expression result should be true");

    response = [runner execute:@"\"locationSDK\" entryToken ( entryDataTypes && entryToken in {\"LKUGLocationInitSettings\", \"init\"}" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertEqual(response.code, 103, @"parseWordToNode:oMgr:fMrg: | invald func entryToken");
    
    response = [runner execute:@"123 12" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertEqual(response.code, 100, @"expression is unknown");

    response = [runner execute:@"8 in {8, 9} && 'dd' in {'dd', 'cc'} && 8+2>8 &&  && 'dd'=='dd' && 8*2>8 && 7 in {7, 9} && 'aa' in {'aa', 'bb'} && 16+2>8 && 'bb'=='bb' && 6*2>8" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertEqual(response.code, LKREEXPRPARAM_NUM_NOT_MATCH, @"execute:withEnv: | Empty param for operator &&");

    response = [runner execute:@"1 && 1 != 2 && 8 + 2 >= 10 && 6 <= 7 && 8 > 4 && 6 < 8 && 2 -1 && 1 * 2 && 8 / 4 && 5 % 1" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertEqual(response.code, 0, @"expression is valiable");
    XCTAssertFalse(response.result == resulttrue, @"expression result should be false");

    response = [runner execute:@"1 != 1 || !1" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertEqual(response.code, 0, @"expression is valiable");
    XCTAssertFalse(response.result == resulttrue, @"expression result should be false");

    response = [runner execute:@"{1.2, 2.4, 3} != {5, 6, 7}" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertEqual(response.code, 0, @"expression is valiable");
    XCTAssertTrue(response.result == resulttrue, @"expression result should be true");
    
    response = [runner execute:@"{} == {}" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertEqual(response.code, 0, @"expression is valiable");
    XCTAssertTrue(response.result == resulttrue, @"expression result should be true");
    
    // array
    response = [runner execute:@"array(1,2,3)" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertEqual(response.code, 0, @"expression is valiable");
    NSMutableArray *expectedResult = [[NSMutableArray alloc] initWithObjects:@1, @2, @3, nil];
    XCTAssertTrue([response.result isKindOfClass:[NSMutableArray class]] && [response.result isEqualToArray:expectedResult], @"expression result should be true");
    
    response = [runner execute:@"array(t)" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertEqual(response.code, 0, @"expression is valiable");
    XCTAssertTrue([response.result isKindOfClass:[NSMutableArray class]] && [LKREChecker isLKREParamMissing:[response.result firstObject]], @"expression result should be true");
    
    // SecondsFromNow
    response = [runner execute:@"SecondsFromNow(1,2,3)" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertEqual(response.code, 105, @"expression is invalid");
    
    response = [runner execute:@"SecondsFromNow(0)" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertEqual(response.code, 0, @"expression is valiable");
    
    response = [runner execute:@"SecondsFromNow(aaa)" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertEqual(response.code, 0, @"expression is valiable");
    XCTAssertTrue([LKREChecker isLKREParamMissing:response.result], @"expression result should be true");
    
    // IsExisted
    response = [runner execute:@"IsExisted(1,2)" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertEqual(response.code, 105, @"expression is invalid");
    
    response = [runner execute:@"IsExisted(1) == true" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertEqual(response.result, resulttrue, @"expression result should be true");
    
    response = [runner execute:@"IsExisted(a) == false" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue(response.result == resulttrue, @"expression result should be true");

    // IsNull
    response = [runner execute:@"IsNull(1,2,3)" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertEqual(response.code, 105, @"expression is invalid");
    
    response = [runner execute:@"IsNull(null)" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue(response.result == resulttrue, @"expression result should be true");
    
    response = [runner execute:@"IsNull(a)" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue([LKREChecker isLKREParamMissing:response.result] == true, @"expression result should be true");
    
    // +
    response = [runner execute:@"1 + " preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertEqual(response.code, 105, @"expression is invalid");
    
    response = [runner execute:@"111.1 - 11f == 100.1" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue(response.result == resulttrue, @"expression result should be true");
    
    response = [runner execute:@"100d - 1.1 == 98.9" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue(response.result == resulttrue, @"expression result should be true");
    
    response = [runner execute:@"1 + a" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue([LKREChecker isLKREParamMissing:response.result] == true, @"expression result should be true");
    
    response = [runner execute:@"1 + 2 + 3 + 4 == 10" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue(response.result == resulttrue, @"expression result should be true");
    
    response = [runner execute:@"(1 + 2 + 3 + 4) * 2 == 20" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue(response.result == resulttrue, @"expression result should be true");
    
    response = [runner execute:@"(1 + 2 + 3 + 4) * 2 / 4 % 3 == 2" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue(response.result == resulttrue, @"expression result should be true");
    
    NSArray *array = [runner commandsWithPreCache:@"1+2"];
    XCTAssertTrue([array count] == 3, @"expression result should be true");
    
    // cache
    response = [runner execute:@"111.1 - 11f == 100.1" preCommands:nil withEnv:env uuid:nil disableCache:NO];
    XCTAssertTrue(response.result == resulttrue, @"expression result should be true");
    
    response = [runner execute:@"100d - 1.1 == 98.9" preCommands:nil withEnv:env uuid:nil disableCache:NO];
    XCTAssertTrue(response.result == resulttrue, @"expression result should be true");
    
    response = [runner execute:@"1 + a" preCommands:nil withEnv:env uuid:nil disableCache:NO];
    XCTAssertTrue([LKREChecker isLKREParamMissing:response.result] == true, @"expression result should be true");
    
    response = [runner execute:@"1 + 2 + 3 + 4 == 10" preCommands:nil withEnv:env uuid:nil disableCache:NO];
    XCTAssertTrue(response.result == resulttrue, @"expression result should be true");
    
    response = [runner execute:@"(1 + 2 + 3 + 4) * 2 == 20" preCommands:nil withEnv:env uuid:nil disableCache:NO];
    XCTAssertTrue(response.result == resulttrue, @"expression result should be true");
    
    response = [runner execute:@"(1 + 2 + 3 + 4) * 2 / 4 % 3 == 2" preCommands:nil withEnv:env uuid:nil disableCache:NO];
    XCTAssertTrue(response.result == resulttrue, @"expression result should be true");
    
    // ==
    response = [runner execute:@"1 == a" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue([LKREChecker isLKREParamMissing:response.result] == true, @"expression result should be true");
    
    response = [runner execute:@"{1,2} == {1,2}" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue(response.result == resulttrue, @"expression result should be true");
    
    response = [runner execute:@"{1,2} == {2,1}" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue(response.result == resultfalse, @"expression result should be false");

    response = [runner execute:@"{1,2} != {1,\"2\"}" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue(response.result == resulttrue, @"expression result should be true");
    
    // !=
    response = [runner execute:@"1 != a" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue([LKREChecker isLKREParamMissing:response.result] == true, @"expression result should be true");
    
    // -
    response = [runner execute:@"1 - a" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue([LKREChecker isLKREParamMissing:response.result] == true, @"expression result should be true");
    
    // &&
    response = [runner execute:@"ture && a" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue([LKREChecker isLKREParamMissing:response.result] == true, @"expression result should be true");
    
    response = [runner execute:@"false && a" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue(response.result == resultfalse, @"expression result should be false");
    
    // ||
    response = [runner execute:@"false || a" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue([LKREChecker isLKREParamMissing:response.result] == true, @"expression result should be true");
    
    response = [runner execute:@"true || a" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue(response.result == resulttrue, @"expression result should be true");
    
    // <=
    response = [runner execute:@"1 <= a" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue([LKREChecker isLKREParamMissing:response.result] == true, @"expression result should be true");
    
    // <=
    response = [runner execute:@"1 <= a" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue([LKREChecker isLKREParamMissing:response.result] == true, @"expression result should be true");
    
    // <
    response = [runner execute:@"1 < a" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue([LKREChecker isLKREParamMissing:response.result] == true, @"expression result should be true");
    
    // <=
    response = [runner execute:@"1 <= a" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue([LKREChecker isLKREParamMissing:response.result] == true, @"expression result should be true");
    
    // >=
    response = [runner execute:@"1 >= a" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue([LKREChecker isLKREParamMissing:response.result] == true, @"expression result should be true");
    
    // >
    response = [runner execute:@"1 > a" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue([LKREChecker isLKREParamMissing:response.result] == true, @"expression result should be true");
    
    // !
    response = [runner execute:@"!a" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue([LKREChecker isLKREParamMissing:response.result] == true, @"expression result should be true");
    
    // *
    response = [runner execute:@"1 * a" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue([LKREChecker isLKREParamMissing:response.result] == true, @"expression result should be true");
    
    // /
    response = [runner execute:@"1 / a" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue([LKREChecker isLKREParamMissing:response.result] == true, @"expression result should be true");
    
    // %
    response = [runner execute:@"1 % a" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue([LKREChecker isLKREParamMissing:response.result] == true, @"expression result should be true");
    
    // in
    response = [runner execute:@"1 in {a,2}" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue([LKREChecker isLKREParamMissing:response.result] == true, @"expression result should be true");
    
    // hasIn
    response = [runner execute:@"1 hasIn {a,2}" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue([LKREChecker isLKREParamMissing:response.result] == true, @"expression result should be true");
    
    response = [runner execute:@"1 hasIn {a,1,2}" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue(response.result == resulttrue, @"expression result should be true");

    response = [runner execute:@"1 hasIn {3,2}" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue(response.result == resultfalse, @"expression result should be false");
    
    response = [runner execute:@"{2,3} hasIn {a,1,2}" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue(response.result == resulttrue, @"expression result should be true");

    response = [runner execute:@"{1,4} hasIn {3,2}" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue(response.result == resultfalse, @"expression result should be false");
    
    response = [runner execute:@"{a,1} hasIn {3,2}" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertTrue([LKREChecker isLKREParamMissing:response.result] == true, @"expression result should be true");

    // null
    response = [runner execute:@"null == 1" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertEqual(response.code, 0, @"expression is valiable");
    XCTAssertTrue(response.result == resultfalse, @"expression result should be false");
    
    response = [runner execute:@"null == null" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertEqual(response.code, 0, @"expression is valiable");
    XCTAssertTrue(response.result == resulttrue, @"expression result should be true");
    
    response = [runner execute:@"null != 1" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertEqual(response.code, 0, @"expression is valiable");
    XCTAssertTrue(response.result == resulttrue, @"expression result should be true");
    
    response = [runner execute:@"null != null" preCommands:nil withEnv:env uuid:nil disableCache:YES];
    XCTAssertEqual(response.code, 0, @"expression is valiable");
    XCTAssertTrue(response.result == resultfalse, @"expression result should be true");
}

@end
