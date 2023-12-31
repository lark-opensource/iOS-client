//
//  TestKeychain.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/9.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RangersAppLog/BDAutoTrackKeychain.h>

@interface TestKeychain : XCTestCase

@end

@implementation TestKeychain

- (void)testReadNilValue {
    XCTAssertNil(bd_keychain_load(@"Test"));
}

//errSecMissingEntitlement
//- (void)testReadValue {
//    NSString *value = [NSUUID UUID].UUIDString;
//    XCTAssertTrue(bd_keychain_save(@"TestKey",value));
//    XCTAssertNotNil(bd_keychain_load(@"TestKey"));
//    XCTAssertEqualObjects(bd_keychain_load(@"TestKey"), value);
//}
//errSecMissingEntitlement
//- (void)testSaveNilValue {
//    NSString *key = [NSUUID UUID].UUIDString;
//    XCTAssertTrue(bd_keychain_save(key,@"TestValue"));
//    XCTAssertNotNil(bd_keychain_load(key));
//    XCTAssertTrue(bd_keychain_save(key,nil));
//    XCTAssertNil(bd_keychain_load(key));
//}

@end
