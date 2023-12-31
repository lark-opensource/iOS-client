//
//  TestUtility.m
//  BDTuring_Tests
//
//  Created by bob on 2019/9/9.
//  Copyright © 2019 bob. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <BDTuring/NSDictionary+BDTuring.h>
#import <BDTuring/BDTuringUtility.h>

@interface TestUtility : XCTestCase

@end

@implementation TestUtility

- (void)testDictionary {
    NSDictionary *param = @{@"Test1":@"1",
                            @"Test2":@(2),
                            @"Test3":@(false),
                            };

    XCTAssertEqual([param turing_integerValueForKey:@"Test1"], 1);
    XCTAssertEqual([param turing_integerValueForKey:@"Test2"], 2);

    XCTAssertEqual([param turing_integerValueForKey:@"Test3"], 0);

    XCTAssertEqualObjects([param turing_stringValueForKey:@"Test1"],@"1");
    XCTAssertEqualObjects([param turing_stringValueForKey:@"Test2"],@"2");
    XCTAssertEqualObjects([param turing_stringValueForKey:@"Test3"],@"0");

    XCTAssertNil([param turing_arrayValueForKey:@"Test01"]);
    XCTAssertNil([param turing_dictionaryValueForKey:@"Test01"]);
}

- (void)testInterval {
    XCTestExpectation *exception = [self expectationWithDescription:@"interval"];
    long long interval12 = turing_currentIntervalMS();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        long long interval22 = turing_currentIntervalMS();
        /// dispatch_after 1s不准确，有0.02s误差
        XCTAssertEqualWithAccuracy(interval12, interval22, 1100);
        [exception fulfill];
    });

    [self waitForExpectations:@[exception] timeout:4];
}

- (void)testQueryFromDictionary {
    NSString *all = @"?!@#$^&%*+,:;='\"`<>()[]{}/\\| "; ///
    all = @"\"#%<>[\\]^`{|}"; /// query allowed
    __block NSInteger index = 1;
    NSMutableDictionary<NSString *, NSString *> *param = [NSMutableDictionary new];
    [all enumerateSubstringsInRange:NSMakeRange(0, all.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString * substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        [param setValue:substring forKey:[NSString stringWithFormat:@"Test_%zd", index++]];
    }];

    NSString *queryFromDictionary = turing_queryFromDictionary(param);
    [param.allValues enumerateObjectsUsingBlock:^(NSString * obj, NSUInteger idx, BOOL *stop) {
        XCTAssertFalse([queryFromDictionary containsString:obj] && ![obj isEqualToString:@"%"]);
    }];
}

- (void)testPath {
    XCTAssertEqualObjects(turing_sandBoxDocumentsPath(), turing_sandBoxDocumentsPath());
    XCTAssertEqualObjects(turing_sdkDocumentPath(), turing_sdkDocumentPath());

    NSString *appid = @"1111";
    NSString *path = turing_sdkDocumentPathForAppID(appid);
    XCTAssertTrue([path containsString:appid]);
    XCTAssertTrue([path containsString:@"bd.turing"]);
    XCTAssertTrue([path containsString:@"Documents"]);

    NSString *appid2 = @"1112";
    NSString *path2 = turing_sdkDocumentPathForAppID(appid2);
    XCTAssertNotEqualObjects(path, path2);
    XCTAssertNotEqualObjects(path, path2);

    XCTAssertEqualObjects(turing_sdkDatabaseFile(), turing_sdkDatabaseFile());

    BOOL isDir = NO;
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]);
    XCTAssertTrue(isDir);

    isDir = NO;
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:path2 isDirectory:&isDir]);
    XCTAssertTrue(isDir);
}


@end
