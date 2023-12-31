//
//  TestConfigService.m
//  BDTuring_Tests
//
//  Created by bob on 2019/10/14.
//  Copyright © 2019 Bytedance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <BDTuring/BDTuringConfig+Parameters.h>

@interface TestConfigService : XCTestCase

@end

@implementation TestConfigService

- (void)setUp {
    
}

- (void)testService {

    BDTuringConfig *config = [BDTuringConfig new];
    config.appID = @"123";
    config.channel = @"App Store";

    NSDictionary *result01 = [config turingWebURLQueryParameters];
    NSDictionary *result02 = [config turingWebURLQueryParameters];
    XCTAssertEqualObjects(result01, result02);
    
    NSDictionary *result11 = [config requestPostParameters];
    NSDictionary *result12 = [config requestPostParameters];
    XCTAssertEqualObjects(result11, result12);
}



@end
