//
//  TestStatePersistancy.m
//  RangersAppLog-Unit-Tests
//
//  Created by 朱元清 on 2020/12/2.
//

#import <XCTest/XCTest.h>
#import "BDAutoTrackTracer.h"
#import "BDAutoTrackTraceDAO.h"
#import "BDAutoTrackTraceState.h"
#import "BDAutoTrackMMap.h"
#include "TraceHeader.h"

@interface TestStatePersistancy : XCTestCase

@end

@implementation TestStatePersistancy {
    BDAutoTrackTracer *tracer;
    BDAutoTrackTraceDAO *dao;
    BDAutoTrackMMap *mmap;
}

- (void)setUp {
    tracer = [[BDAutoTrackTracer alloc] initWithTrack:nil];
    [tracer start];
    
    [NSThread sleepForTimeInterval:0.01];  // sleep 0.01s 等待tracer启动
    
    // 说明: DAO/MMap是Tracer组件私有类。外界不应该访问。不过单测中可以hack。
    dao = [tracer performSelector:@selector(dao)];
    mmap = [dao performSelector:@selector(MMap)];
}

- (void)tearDown {
    [mmap destroy];
}

- (void)testLogTraces_and_ReadThemBack {
    NSString *traceName = @"unittest",
             *traceKey1 = @"unittest-key1",
             *traceKey2 = @"unittest-key2";
    
    [tracer traceStateName:traceName key:traceKey1 addCount:33]; // + 33
    [tracer traceStateName:traceName key:traceKey1 addCount:66]; // + 66
    
    [tracer traceStateName:traceName key:traceKey2 addDuration:10000 autoCount:YES];
    
    [NSThread sleepForTimeInterval:0.01];  // sleep 0.01s 等待tracer在子线程完成写入.
    
    BDAutoTrackTraceState *state1 = [dao stateWithName:traceName key:traceKey1];
    BDAutoTrackTraceState *state2 = [dao stateWithName:traceName key:traceKey2];
    
    XCTAssertTrue([state1.name isEqualToString:traceName]);
    XCTAssertTrue([state1.key isEqualToString:traceKey1]);
    XCTAssertEqual(state1.count, 99);
    XCTAssertEqual(state1.duration, 0);  // 默认为0
    
    XCTAssertTrue([state2.name isEqualToString:traceName]);
    XCTAssertTrue([state2.key isEqualToString:traceKey2]);
    XCTAssertEqual(state2.count, 1);  // 因为 AutoCount=YES
    XCTAssertEqual(state2.duration, 10000);
    
}

- (void)testLogTraces_and_OffsetIncrements {
    struct TraceHeader *traceHeader = mmap.memory;
    XCTAssertEqual(traceHeader->offset, traceHeader->headerSize);
    
    NSString *traceName = @"unittest",
             *traceKey1 = @"unittest-key1",
             *traceKey2 = @"unittest-key2";
    
    [tracer traceStateName:traceName key:traceKey1 addCount:33]; // + 33
    [NSThread sleepForTimeInterval:0.01];  // sleep 0.01s 等待tracer在子线程完成写入.
    XCTAssertEqual(traceHeader->offset, traceHeader->headerSize + kRALTraceStateStructSize);
    
    [tracer traceStateName:traceName key:traceKey1 addCount:66]; // + 66
    [NSThread sleepForTimeInterval:0.01];  // sleep 0.01s 等待tracer在子线程完成写入.
    XCTAssertEqual(traceHeader->offset, traceHeader->headerSize + kRALTraceStateStructSize);
    
    [tracer traceStateName:traceName key:traceKey2 addDuration:10000 autoCount:YES];
    [NSThread sleepForTimeInterval:0.01];  // sleep 0.01s 等待tracer在子线程完成写入.
    XCTAssertEqual(traceHeader->offset, traceHeader->headerSize + kRALTraceStateStructSize * 2);
}


@end
