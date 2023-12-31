//
//  TestRequestURLs.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/11.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RangersAppLog/BDTrackerCoreConstants.h>
#import <RangersAppLog/RangersAppLog.h>
#import <RangersAppLog/BDAutoTrackURLHostProvider.h>

@interface BDAutoTrackURLHostProvider (Test)

@property (strong, nonatomic) NSMutableDictionary<BDAutoTrackServiceVendor, id<BDAutoTrackURLHostItemProtocol>> *hostItems;

@end

@interface TestRequestURLs : XCTestCase


@end

@implementation TestRequestURLs

- (void)testRequestURLs {
    NSArray<NSNumber *> *types = @[@(BDAutoTrackRequestURLRegister),
                                   @(BDAutoTrackRequestURLActivate),
                                   @(BDAutoTrackRequestURLSettings),
                                   @(BDAutoTrackRequestURLABTest),
                                   @(BDAutoTrackRequestURLLog),
                                   @(BDAutoTrackRequestURLLogBackup),];

    NSArray<BDAutoTrackServiceVendor> *vendors = @[
#if __has_include(<RangersAppLog/BDAutoTrackURLHostItemCN.h>)
        BDAutoTrackServiceVendorCN,
#endif
#if __has_include(<RangersAppLog/BDAutoTrackURLHostItemSG.h>)
        BDAutoTrackServiceVendorSG,
#endif
#if __has_include(<RangersAppLog/BDAutoTrackURLHostItemVA.h>)
        BDAutoTrackServiceVendorVA,
#endif
    ];

    for (BDAutoTrackServiceVendor vendor in vendors) {
        id<BDAutoTrackURLHostItemProtocol> item = [[BDAutoTrackURLHostProvider sharedInstance].hostItems objectForKey:vendor];
        XCTAssertNotNil(item);
        NSMutableSet<NSString *> *requestURLs = [NSMutableSet set];
        [types enumerateObjectsUsingBlock:^(NSNumber * obj, NSUInteger idx, BOOL *stop) {
            BDAutoTrackRequestURLType type = [obj integerValue];
            NSString *requestURL = [item URLForURLType:type];
            XCTAssertNotNil(requestURL);
            XCTAssertNotNil([NSURL URLWithString:requestURL]);
            XCTAssertFalse([requestURLs containsObject:requestURL]);
            [requestURLs addObject:requestURL];
        }];
    }
}

@end
