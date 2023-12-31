//
//  TestRequest.m
//  BDTuring_Tests
//
//  Created by bob on 2019/10/14.
//  Copyright © 2019 Bytedance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <BDTuring/BDTNetworkManager.h>
#import <BDTuring/BDTuringServiceCenter.h>
#import <BDTuring/BDTuringConfig+Parameters.h>

@interface TestRequest : XCTestCase<BDTuringConfigDelegate>

@end

@implementation TestRequest

- (void)testExample {

    BDTuringConfig *config = [BDTuringConfig new];
    config.appID = @"123";
    config.channel = @"App Store";
    config.delegate = self;
}

- (NSString *)deviceID {
    return @"40868255089";
}

- (NSString *)sessionID {
    return [NSUUID UUID].UUIDString;
}

- (NSString *)installID {
    return @"1234";
}

- (nullable NSString *)userID {
    return @"40868255089";
}

- (nullable NSString *)secUserID {
    return @"xxx";
}

@end
