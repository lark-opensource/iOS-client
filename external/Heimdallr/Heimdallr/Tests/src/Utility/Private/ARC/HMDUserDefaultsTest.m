//
//  HMDUserDefaultsTest.m
//  Pods
//
//  Created by bytedance on 2022/7/6.
//

#import <XCTest/XCTest.h>
#import "HMDUserDefaults.h"

@interface HMDUserDefaultsTest : XCTestCase

@end

@implementation HMDUserDefaultsTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)test_userdefaults_setobject {
    NSDictionary *nonSerializableObject = @{
        @"HMDUserDefaultsTest" : self
    };
    
    XCTAssertNoThrow([[HMDUserDefaults standardUserDefaults] setObject:nonSerializableObject forKey:@"nonSerializableObject"], @"HMDUserDefaults: HMDUserDefaults should not be inserted by nonSerializableObject");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
