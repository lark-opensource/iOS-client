//
//  TestURLConfig.m
//  BDTuring_Tests
//
//  Created by bob on 2019/10/14.
//  Copyright © 2019 Bytedance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <BDTuring/BDTNetworkManager.h>
#import <BDTuring/BDTuringServiceCenter.h>
#import <BDTuring/BDTuringConfig+Parameters.h>
#import <BDTuring/BDTuringSettings.h>
#import <BDTuring/BDTuringSettingsKeys.h>
#import <BDTuring/BDTuringCoreConstant.h>

@interface TestURLConfig : XCTestCase<BDTuringConfigDelegate>

@end

@implementation TestURLConfig

- (void)setUp {
    
}

- (void)testNotNil {
    BDTuringConfig *config = [BDTuringConfig new];
    config.appID = @"123";
    config.channel = @"App Store";
    config.delegate = self;
    NSArray<NSDictionary *> *requests = @[
        @{
            @"plugin":kBDTuringSettingsPluginCommon,
            @"region":kBDTuringRegionCN,
            @"type":kBDTuringSettingsHost,
        },
        @{
            @"plugin":kBDTuringSettingsPluginPicture,
            @"region":kBDTuringRegionCN,
            @"type":kBDTuringSettingsURL,
        },
        @{
            @"plugin":kBDTuringSettingsPluginPicture,
            @"region":kBDTuringRegionCN,
            @"type":kBDTuringSettingsHost,
        },
        @{
            @"plugin":kBDTuringSettingsPluginQA,
            @"region":kBDTuringRegionCN,
            @"type":kBDTuringSettingsURL,
        },
        @{
            @"plugin":kBDTuringSettingsPluginQA,
            @"region":kBDTuringRegionCN,
            @"type":kBDTuringSettingsHost,
        },
        @{
            @"plugin":kBDTuringSettingsPluginSMS,
            @"region":kBDTuringRegionCN,
            @"type":kBDTuringSettingsURL,
        },
        @{
            @"plugin":kBDTuringSettingsPluginSMS,
            @"region":kBDTuringRegionCN,
            @"type":kBDTuringSettingsHost,
        },
        @{
            @"plugin":kBDTuringSettingsPluginSeal,
            @"region":kBDTuringRegionCN,
            @"type":kBDTuringSettingsURL,
        },
    ];
    BDTuringSettings *setting = [BDTuringSettings settingsForConfig:config];
    XCTestExpectation *expect = [XCTestExpectation new];
    expect.expectedFulfillmentCount = 1;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [requests enumerateObjectsUsingBlock:^(NSDictionary *request, NSUInteger idx, BOOL *stop) {
            NSString *plugin = [request objectForKey:@"plugin"];
            NSString *region = [request objectForKey:@"region"];
            NSString *type = [request objectForKey:@"type"];
            XCTAssertNotNil([setting requestURLForPlugin:plugin URLType:type region:region]);
        }];
        [expect fulfill];
    });
    
    
    [self waitForExpectations:@[expect] timeout:0.2];
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
