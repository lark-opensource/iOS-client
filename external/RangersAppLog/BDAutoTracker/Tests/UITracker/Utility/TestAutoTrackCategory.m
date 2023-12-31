//
//  TestAutoTrackCategory.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/19.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RangersAppLog/NSObject+AutoTrack.h>
#import <RangersAppLog/UIResponder+AutoTrack.h>
#import <RangersAppLog/UIView+AutoTrack.h>
#import <RangersAppLog/UIViewController+AutoTrack.h>

@interface TestAutoTrackCategory : XCTestCase

@end

@implementation TestAutoTrackCategory

- (void)testNSObject {
    NSObject *obj = [NSObject new];
    BOOL bd_AutoTrackInternalItem =  arc4random() % 2 == 0;;
    obj.bd_AutoTrackInternalItem = bd_AutoTrackInternalItem;
    XCTAssertEqual(bd_AutoTrackInternalItem, obj.bd_AutoTrackInternalItem);
}

- (void)testUIResponder {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    NSString *path1 = [view bd_responderPath];
    XCTAssertNotNil(path1);
    UIView *parent = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    [parent addSubview:view];
    NSString *path2 = [view bd_responderPath];
    XCTAssertNotNil(path2);
    XCTAssertNotEqualObjects(path1, path2);

    UIView *view1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    [parent addSubview:view1];
    NSString *path3 = [view1 bd_responderPath];
    XCTAssertNotNil(path3);
    XCTAssertNotEqualObjects(path3, path2);

    UIViewController *vc = [UIViewController new];
    [vc.view addSubview:parent];
    NSString *path4 = [view1 bd_responderPath];
    XCTAssertNotNil(path4);
    XCTAssertNotEqualObjects(path3, path4);

    UIViewController *parentVC = [UIViewController new];
    [parentVC addChildViewController:vc];
    [parentVC.view addSubview:vc.view];
    [vc didMoveToParentViewController:parentVC];
    NSString *path5 = [view1 bd_responderPath];
    XCTAssertNotNil(path5);
    XCTAssertNotEqualObjects(path5, path4);
}

@end
