//
//  Env.m
//  AppHost-OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2022/12/14.
//

#import <Foundation/Foundation.h>
#include <stdlib.h>
@interface FoundationLoadEnv: NSObject

@end

@implementation FoundationLoadEnv

+ (void)load {
    NSLog(@"FoundationLoadEnv did setenv");
    setenv("IS_TESTING_OPEN_PLATFORM_SDK","1",1);
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"AssertDebugItemCloseKey"];
}

@end
