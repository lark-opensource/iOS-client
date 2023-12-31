//
//  TSPKUtilsTests.m
//  TSPrivacyKit-Unit-Tests
//
//  Created by ByteDance on 2022/11/21.
//

#import <XCTest/XCTest.h>
#import <TSPrivacyKit/TSPKUtils.h>

@interface TSPKUtilsTests : XCTestCase

@end

@implementation TSPKUtilsTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testConcate {
    NSString *concate = [TSPKUtils concateClassName:@"x" method:@"y"];
    
    XCTAssertTrue([concate isEqualToString:@"x:y"], @"should connect with :");
}

@end
