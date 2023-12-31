//
//  TestBridgeCommand.m
//  BDTuring_Tests
//
//  Created by bob on 2019/10/14.
//  Copyright © 2019 Bytedance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <BDTuring/BDTuringPiperCommand.h>
#import <BDTuring/BDTuringPiperConstant.h>

@interface TestBridgeCommand : XCTestCase

@end

@implementation TestBridgeCommand

- (void)testNative {
    NSString *bridgeName = @"bridgeName";
    BDTuringPiperOnHandler callback = ^(NSDictionary * params, BDTuringPiperOnCallback callback) {
        if (callback) callback(BDTuringPiperMsgSuccess, nil);
    };
    BDTuringPiperCommand *command = [[BDTuringPiperCommand alloc] initWithName:bridgeName onHandler:callback];

    XCTAssertEqualObjects(command.bridgeName, bridgeName);
    XCTAssertEqualObjects(command.messageType, BDTuringPiperMsgTypeOn);
    XCTAssertEqual(callback, command.onHandler);
    XCTAssertEqual(BDTuringPiperTypeOn, command.piperType);
}

- (void)testFE {
    NSDictionary *dict = @{
        @"JSSDK": @(2),
        @"__callback_id" : @"bytedcert.goToClose",
        @"__msg_type" : @"on",
        @"func" : @"bytedcert.goToClose",
    };

    BDTuringPiperCommand *command = [[BDTuringPiperCommand alloc] initWithDictionary:dict];

    XCTAssertEqualObjects(command.bridgeName, @"bytedcert.goToClose");
    XCTAssertEqualObjects(command.callbackID, @"bytedcert.goToClose");
    XCTAssertEqualObjects(command.messageType, BDTuringPiperMsgTypeOn);
    XCTAssertNil(command.onHandler);
    XCTAssertEqual(BDTuringPiperTypeOn, command.piperType);

    NSDictionary *dict2 = @{
        @"JSSDK": @(2),
        @"__callback_id" : @"1001",
        @"__msg_type" : @"call",
        @"func" : @"bytedcert.dialogSize",
    };

    BDTuringPiperCommand *command2 = [[BDTuringPiperCommand alloc] initWithDictionary:dict2];
    XCTAssertEqualObjects(command2.bridgeName, @"bytedcert.dialogSize");
    XCTAssertEqualObjects(command2.callbackID, @"1001");
    XCTAssertEqualObjects(command2.messageType, BDTuringPiperMsgTypeCall);
    XCTAssertNil(command2.onHandler);
    XCTAssertEqual(BDTuringPiperTypeCall, command2.piperType);
}

@end
