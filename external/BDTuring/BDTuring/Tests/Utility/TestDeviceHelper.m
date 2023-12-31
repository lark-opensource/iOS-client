//
//  TestDeviceHelper.m
//  BDTuring_Tests
//
//  Created by bob on 2019/9/9.
//  Copyright © 2019 bob. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <BDTuring/BDTuringDeviceHelper.h>
#import "sys/utsname.h"

@interface TestDeviceHelper : XCTestCase

@end

@implementation TestDeviceHelper

- (void)testDeviceHelper {
    XCTAssertEqualObjects([BDTuringDeviceHelper deviceBrand], [UIDevice currentDevice].model);

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    float scale = [[UIScreen mainScreen] scale];
    CGSize resolution = CGSizeMake(screenBounds.size.width * scale, screenBounds.size.height * scale);
    NSString *resolutionString = [NSString stringWithFormat:@"%d*%d", (int)resolution.width, (int)resolution.height];
    XCTAssertEqualObjects([BDTuringDeviceHelper resolutionString], resolutionString);

    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    XCTAssertEqualObjects([BDTuringDeviceHelper systemVersion], systemVersion);
}

@end
