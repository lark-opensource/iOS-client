//
//  TestTraceDAO.m
//  RangersAppLog-Unit-Tests
//
//  Created by 朱元清 on 2021/1/10.
//

#import <XCTest/XCTest.h>
#import "BDAutoTrackTraceDAO.h"
#import "BDAutoTrackMMap.h"
#include "TraceHeader.h"

@interface TestTraceDAO : XCTestCase

@end

@implementation TestTraceDAO

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testInitHeader {
    NSString *randomAppID = [[NSString stringWithFormat:@"%ld", random()] substringToIndex:6];
    BDAutoTrackTraceDAO *dao = [[BDAutoTrackTraceDAO alloc] initWithAppID:randomAppID];
    BDAutoTrackMMap *mmap = [dao performSelector:@selector(MMap)];
    XCTAssertTrue(mmap.size > 0);
    
    struct TraceHeader *initialTrace = mmap.memory;
    XCTAssertEqual(initialTrace->magicCode, kRALTraceFileMagicCode);
    XCTAssertEqual(initialTrace->version, kRALTraceFileVersion);
    XCTAssertEqual(initialTrace->headerSize, sizeof(*initialTrace));
    XCTAssertEqual(initialTrace->headerSize, initialTrace->offset);
}

- (void)testHeaderVersion {
    NSString *randomAppID = [[NSString stringWithFormat:@"%ld", random()] substringToIndex:6];
    BDAutoTrackTraceDAO *dao = [[BDAutoTrackTraceDAO alloc] initWithAppID:randomAppID];
    XCTAssertEqual([dao version], 1);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
