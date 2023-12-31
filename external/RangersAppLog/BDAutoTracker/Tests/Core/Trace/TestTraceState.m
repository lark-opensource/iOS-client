//
//  TestTraceState.m
//  RangersAppLog-Unit-Tests
//
//  Created by 朱元清 on 2020/12/2.
//

#import <XCTest/XCTest.h>
#import "BDAutoTrackTraceState.h"

//extern CFMutableBitVectorRef bd_uint64_to_bitVector(uint64_t num);
//extern uint64_t bd_bitVector_to_uint64(CFBitVectorRef bitVector);

static NSString *stringLength60 = @"0123456789012345678901234567890123456789012345678901234567890123456789";  // len = 60


@interface TestTraceState : XCTestCase

@end

@implementation TestTraceState {
    uint64_t _defaultCount;
    uint64_t _defaultDuration;
    NSString *_defaultName;
    NSString *_defaultKey;
    struct TraceState _defaultState;
}

- (void)setUp {
    _defaultCount = 2020;
    _defaultDuration = 2021;
    _defaultName = @"default_state_name";
    _defaultKey = @"default_state_key";
    
    bzero(&_defaultState, sizeof(_defaultState));
    strncpy(_defaultState.name, [_defaultName UTF8String], kRALTraceStateStringSize - 1);
    strncpy(_defaultState.key , [_defaultKey UTF8String] , kRALTraceStateStringSize - 1);
    _defaultState.count = _defaultCount;
    _defaultState.duration = _defaultDuration;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)test_state_bindMemory {
    BDAutoTrackTraceState *state = [[BDAutoTrackTraceState alloc] initWithBindMemory:&_defaultState];
    
    XCTAssertTrue([state.name isEqualToString: _defaultName]);
    XCTAssertTrue([state.key isEqualToString: _defaultKey]);
    XCTAssertEqual(state.count, _defaultCount);
    XCTAssertEqual(state.duration, _defaultDuration);
}


- (void)test_state_bindMemory_long_name {
    NSString *longName = @"012345678901234567890123456789012345678901234567890";  // len = 51
    XCTAssertEqual([longName length], kRALTraceStateStringSize + 1);
    
    strncpy(_defaultState.name, [longName UTF8String], kRALTraceStateStringSize - 1);

    BDAutoTrackTraceState *state = [[BDAutoTrackTraceState alloc] initWithBindMemory:&_defaultState];
    
//    NSLog(@"name: %@ %zu", state.name, [state.name length]);
    // 长度大于49的字符串应被截断
    NSString *cutLongName = [longName substringToIndex:kRALTraceStateStringSize - 1];
    XCTAssertTrue([state.name isEqualToString: cutLongName]);
    XCTAssertEqual(state.name.length, kRALTraceStateStringSize - 1);
    
    XCTAssertTrue([state.key isEqualToString: _defaultKey]);
    XCTAssertEqual(state.count, _defaultCount);
    XCTAssertEqual(state.duration, _defaultDuration);
}

- (void)test_state_add_count {
    BDAutoTrackTraceState *state = [[BDAutoTrackTraceState alloc] initWithBindMemory:&_defaultState];
    [state addCount:10086];
    XCTAssertEqual(_defaultState.count, _defaultCount + 10086);
}

- (void)test_state_add_duration {
    BDAutoTrackTraceState *state = [[BDAutoTrackTraceState alloc] initWithBindMemory:&_defaultState];
    [state addDuration:1e5];
    XCTAssertEqual(_defaultState.duration, _defaultDuration + 1e5);
}


- (void)test_state_set_count {
    BDAutoTrackTraceState *state = [[BDAutoTrackTraceState alloc] initWithBindMemory:&_defaultState];
    [state setCount:10086];
    XCTAssertEqual(_defaultState.count, 10086);
}

- (void)test_state_set_duration {
    BDAutoTrackTraceState *state = [[BDAutoTrackTraceState alloc] initWithBindMemory:&_defaultState];
    [state setDuration:1e5];
    XCTAssertEqual(_defaultState.duration, 1e5);
}

- (void)test_state_set_name {
    BDAutoTrackTraceState *state = [[BDAutoTrackTraceState alloc] initWithBindMemory:&_defaultState];
    
    // 设置正常Name
    NSString *newName = @"newStateName";
    [state setName:newName];
    XCTAssertTrue([newName isEqualToString:state.name]);
    
    // 设置超长Name应截断
    [state setName:stringLength60];
    NSString *cutLongName = [stringLength60 substringToIndex:kRALTraceStateStringSize - 1];
    XCTAssertTrue([cutLongName isEqualToString:state.name]);
}

- (void)test_state_set_key {
    BDAutoTrackTraceState *state = [[BDAutoTrackTraceState alloc] initWithBindMemory:&_defaultState];
    
    // 设置正常Name
    NSString *newKey = @"newStateKey";
    [state setKey:newKey];
    XCTAssertTrue([newKey isEqualToString:state.key]);
    
    // 设置超长Name应截断
    [state setKey:stringLength60];
    NSString *cutLongKey = [stringLength60 substringToIndex:kRALTraceStateStringSize - 1];
    XCTAssertTrue([cutLongKey isEqualToString:state.key]);
}

- (void)test_to_dictionary {
    BDAutoTrackTraceState *state = [[BDAutoTrackTraceState alloc] initWithBindMemory:&_defaultState];
    NSMutableDictionary *state_as_dictioanry = [state toDictionary];
    NSDictionary *predefinedDictionary = @{
        @"name": _defaultName,
        @"key": _defaultKey,
        @"count": @(_defaultCount),
        @"duration": @(_defaultDuration)
    };
    XCTAssertTrue([state_as_dictioanry isEqualToDictionary:predefinedDictionary]);
}

- (void)test_is_equal_state_equal {
    BDAutoTrackTraceState *state1 = [[BDAutoTrackTraceState alloc] initWithBindMemory:&_defaultState];
    struct TraceState c_state2 = _defaultState;
    BDAutoTrackTraceState *state2 = [[BDAutoTrackTraceState alloc] initWithBindMemory:&c_state2];
    
    XCTAssertTrue([state1 isEqualToState:state1]);
    XCTAssertTrue([state1 isEqualToState:state2]);
    XCTAssertTrue([state2 isEqualToState:state1]);
}

- (void)test_is_equal_state_not_equal_count {
    BDAutoTrackTraceState *state1 = [[BDAutoTrackTraceState alloc] initWithBindMemory:&_defaultState];
    struct TraceState c_state2 = _defaultState;
    c_state2.count += 1;
    BDAutoTrackTraceState *state2 = [[BDAutoTrackTraceState alloc] initWithBindMemory:&c_state2];
    
    XCTAssertFalse([state1 isEqualToState:state2]);
    XCTAssertFalse([state2 isEqualToState:state1]);
}

- (void)test_is_equal_state_not_equal_duration {
    BDAutoTrackTraceState *state1 = [[BDAutoTrackTraceState alloc] initWithBindMemory:&_defaultState];
    struct TraceState c_state2 = _defaultState;
    c_state2.duration += 1;
    BDAutoTrackTraceState *state2 = [[BDAutoTrackTraceState alloc] initWithBindMemory:&c_state2];
    
    XCTAssertFalse([state1 isEqualToState:state2]);
    XCTAssertFalse([state2 isEqualToState:state1]);
}

- (void)test_is_equal_state_not_equal_name {
    BDAutoTrackTraceState *state1 = [[BDAutoTrackTraceState alloc] initWithBindMemory:&_defaultState];
    struct TraceState c_state2 = _defaultState;
    strncpy(c_state2.name, "im-new-name", kRALTraceStateStringSize-1);
    BDAutoTrackTraceState *state2 = [[BDAutoTrackTraceState alloc] initWithBindMemory:&c_state2];
    
    XCTAssertFalse([state1 isEqualToState:state2]);
    XCTAssertFalse([state2 isEqualToState:state1]);
}


- (void)test_is_equal_state_not_equal_key {
    BDAutoTrackTraceState *state1 = [[BDAutoTrackTraceState alloc] initWithBindMemory:&_defaultState];
    struct TraceState c_state2 = _defaultState;
    strncpy(c_state2.key, "im-new-key", kRALTraceStateStringSize-1);
    BDAutoTrackTraceState *state2 = [[BDAutoTrackTraceState alloc] initWithBindMemory:&c_state2];
    
    XCTAssertFalse([state1 isEqualToState:state2]);
    XCTAssertFalse([state2 isEqualToState:state1]);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
