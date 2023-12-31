//
//  TestSandBoxHelper.m
//  BDTuring_Tests
//
//  Created by bob on 2019/9/9.
//  Copyright © 2019 bob. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <BDTuring/BDTuringSandBoxHelper.h>

@interface TestSandBoxHelper : XCTestCase

@end

@implementation TestSandBoxHelper

- (void)testAppVersion {
    NSString *appVersion = [BDTuringSandBoxHelper appVersion];
    NSString *appVersionEx = [[NSBundle mainBundle].infoDictionary objectForKey: @"CFBundleShortVersionString"];
    XCTAssertEqualObjects(appVersion, appVersionEx);
}

- (void)testAppIdentifier {
//    NSString *bundleIdentifierEx = [[NSBundle bundleForClass:[self class]].infoDictionary objectForKey: @"CFBundleIdentifier"];
//    XCTAssertNotNil(bundleIdentifierEx);
//    XCTAssertEqualObjects([BDTuringSandBoxHelper bundleIdentifier], bundleIdentifierEx);
}

@end
