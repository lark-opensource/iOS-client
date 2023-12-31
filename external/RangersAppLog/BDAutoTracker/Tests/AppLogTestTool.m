//
//  AppLogTestTool.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/11/12.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import "AppLogTestTool.h"

@implementation AppLogTestTool

+ (NSBundle *)testBundle {
    static NSBundle *sdkBundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:@"RangersAppLog-Tests" withExtension:@"bundle"];
        if (url) {
            sdkBundle = [NSBundle bundleWithURL:url];
        }
    });

    return sdkBundle;
}

+ (NSDictionary *)fakeRegisterResult {
    NSString *fakeDataPath = [[self testBundle] pathForResource:@"fakeRegisterResult" ofType:@"plist"];
    return  [NSDictionary dictionaryWithContentsOfFile:fakeDataPath];
}

+ (NSDictionary *)fakeRequestData {
    NSString *fakeDataPath = [[self testBundle] pathForResource:@"fakeRequestData" ofType:@"plist"];
    return  [NSDictionary dictionaryWithContentsOfFile:fakeDataPath];
}


@end
