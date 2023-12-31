//
//  TestTrack.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/16.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <RangersAppLog/BDAutoTrack.h>
#import <RangersAppLog/BDAutoTrackServiceCenter.h>

@interface TestTrack : XCTestCase

@property (nonatomic, copy) NSString *appID;
@property (nonatomic, strong) BDAutoTrack *track;

@end

@implementation TestTrack

- (void)setUp {
    self.appID = @"157937";/// no ab this appid
    [[BDAutoTrackServiceCenter defaultCenter] unregisterAllServices];
}

@end
