//
//  TestTrackInfoCategory.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/20.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RangersAppLog/UIBarButtonItem+TrackInfo.h>
#import <RangersAppLog/UIBarButtonItem+AutoTrack.h>
#import <RangersAppLog/UIView+TrackInfo.h>
#import <RangersAppLog/UIViewController+TrackInfo.h>

@interface TestTrackInfoCategory : XCTestCase

@end

@implementation TestTrackInfoCategory


- (void)testUIBarButtonItem {
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"" style:(UIBarButtonItemStylePlain) target:nil action:nil];
    XCTAssertNotNil(item);
    NSString *bdAutoTrackID = [NSUUID UUID].UUIDString;
    NSString *bdAutoTrackContent = [NSUUID UUID].UUIDString;
    item.bdAutoTrackID = bdAutoTrackID;
    item.bdAutoTrackContent = bdAutoTrackContent;
    item.bdAutoTrackExtraInfos = @{};

    XCTAssertNotNil(item.bdAutoTrackID);
    XCTAssertNotNil(item.bdAutoTrackContent);
    XCTAssertNotNil(item.bdAutoTrackExtraInfos);

    XCTAssertEqualObjects(item.bdAutoTrackID, bdAutoTrackID);
    XCTAssertEqualObjects(item.bdAutoTrackContent, bdAutoTrackContent);
    XCTAssertEqualObjects(item.bdAutoTrackExtraInfos, @{});

    NSMutableDictionary *result1 = [NSMutableDictionary new];
    NSMutableDictionary *result2 = [NSMutableDictionary new];
    [item bd_fillCustomInfo:result1];
    [item bd_fillCustomInfo:result2];
    XCTAssertEqualObjects(result1, result2);
}

- (void)testUIView {
    UIView *item = [UIView new];
    XCTAssertNotNil(item);
    NSString *bdAutoTrackID = [NSUUID UUID].UUIDString;
    NSString *bdAutoTrackContent = [NSUUID UUID].UUIDString;
    item.bdAutoTrackViewID = bdAutoTrackID;
    item.bdAutoTrackViewContent = bdAutoTrackContent;
    item.bdAutoTrackExtraInfos = @{};

    XCTAssertNotNil(item.bdAutoTrackViewID);
    XCTAssertNotNil(item.bdAutoTrackViewContent);
    XCTAssertNotNil(item.bdAutoTrackExtraInfos);

    XCTAssertEqualObjects(item.bdAutoTrackViewID, bdAutoTrackID);
    XCTAssertEqualObjects(item.bdAutoTrackViewContent, bdAutoTrackContent);
    XCTAssertEqualObjects(item.bdAutoTrackExtraInfos, @{});
}

- (void)testUIViewController {
    UIViewController *item = [UIViewController new];
    XCTAssertNotNil(item);
    NSString *bdAutoTrackID = [NSUUID UUID].UUIDString;
    NSString *bdAutoTrackContent = [NSUUID UUID].UUIDString;
    item.bdAutoTrackPageID = bdAutoTrackID;
    item.bdAutoTrackPageTitle = bdAutoTrackContent;
    item.bdAutoTrackExtraInfos = @{};

    XCTAssertNotNil(item.bdAutoTrackPageTitle);
    XCTAssertNotNil(item.bdAutoTrackPageID);
    XCTAssertNotNil(item.bdAutoTrackExtraInfos);

    XCTAssertEqualObjects(item.bdAutoTrackPageID, bdAutoTrackID);
    XCTAssertEqualObjects(item.bdAutoTrackPageTitle, bdAutoTrackContent);
    XCTAssertEqualObjects(item.bdAutoTrackExtraInfos, @{});
}

@end
