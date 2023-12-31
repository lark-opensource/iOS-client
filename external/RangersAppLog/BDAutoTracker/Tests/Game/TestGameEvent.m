//
//  TestGameEvent.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/11.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RangersAppLog/BDAutoTrackConfig+AppLog.h>
#import <RangersAppLog/BDAutoTrack+Private.h>
#import <RangersAppLog/BDAutoTrack+Game.h>
#import <RangersAppLog/BDAutoTrack+GameTrack.h>
#import <RangersAppLog/BDAutoTrackSwizzle.h>

#import <objc/runtime.h>

@interface TestGameEvent : XCTestCase

@property (nonatomic, strong) BDAutoTrack *track;

@end

@implementation TestGameEvent

- (void)setUp {
    BDAutoTrackConfig *config = [BDAutoTrackConfig configWithAppID:@"159486" launchOptions:nil];
    config.channel = @"App Store";
    config.appName = @"dp_tob_sdk_test2";
    self.track = [BDAutoTrack trackWithConfig:config];
}

- (void)tearDown {
    
}

- (void)testEvents {
    static IMP originIMP = nil;
    __block NSInteger index = 0;
    XCTAssertEqual(index, 0);
    id block = ^(BDAutoTrack *_self, NSString *event ,NSDictionary *params){
        XCTAssertNotNil(event);
        XCTAssertNotNil(params);
        XCTAssertTrue([NSJSONSerialization isValidJSONObject:params]);
        if (originIMP) {
            index++;
            BOOL success = ((BOOL ( *)(id, SEL, NSString *, NSDictionary *))originIMP)(_self, @selector(eventV3:params:), event, params);
            XCTAssertTrue(success);
        }
    };
    
    // 保存原函数和原函数类型字符串，用于后续恢复
    Method originMethod = class_getInstanceMethod([BDAutoTrack class], @selector(eventV3:params:));
    const char *originMethodTypes = method_getTypeEncoding(originMethod);
    originIMP = bd_swizzle_instance_methodWithBlock([BDAutoTrack class], @selector(eventV3:params:), block);
    

    /// events
    XCTAssertEqual(index, 0);
    [self.track registerEventByMethod:@"Method" isSuccess:YES];
    XCTAssertEqual(index, 1);
    [self.track loginEventByMethod:@"Method" isSuccess:YES];
    XCTAssertEqual(index, 2);
    [self.track accessAccountEventByType:@"type" isSuccess:YES];
    XCTAssertEqual(index, 3);
    [self.track questEventWithQuestID:@"id"
                            questType:@"questType"
                            questName:@"questName"
                           questNumer:1
                          description:@"description"
                            isSuccess:1];
    XCTAssertEqual(index, 4);
    [self.track updateLevelEventWithLevel:1];
    XCTAssertEqual(index, 5);
    [self.track viewContentEventWithContentType:@"type"
                                    contentName:@"type"
                                      contentID:@"id"];
    XCTAssertEqual(index, 6);
    [self.track addCartEventWithContentType:@"type"
                                contentName:@"name"
                                  contentID:@"id"
                              contentNumber:1
                                  isSuccess:YES];
    XCTAssertEqual(index, 7);
    [self.track checkoutEventWithContentType:@"type"
                                 contentName:@"name"
                                   contentID:@"id"
                               contentNumber:1
                           isVirtualCurrency:YES
                             virtualCurrency:@"virtualCurrency"
                                    currency:@"currency"
                             currency_amount:1
                                   isSuccess:YES];
    XCTAssertEqual(index, 8);
    [self.track purchaseEventWithContentType:@"type"
                                 contentName:@"contentName"
                                   contentID:@"contentID"
                               contentNumber:1
                              paymentChannel:@"paymentChannel"
                                    currency:@"currency"
                             currency_amount:1
                                   isSuccess:YES];
    XCTAssertEqual(index, 9);
    [self.track accessAccountEventByType:@"Type" isSuccess:YES];
    XCTAssertEqual(index, 10);
    [self.track addToFavouriteEventWithContentType:@"type"
                                       contentName:@"contentName"
                                         contentID:@"contentID"
                                     contentNumber:1
                                         isSuccess:YES];
    
    // 复原
    class_replaceMethod([BDAutoTrack class], @selector(eventV3:params:), originIMP, originMethodTypes);
}

@end
