//
//  BDTuringSandBoxHelper.m
//  BDTuring
//
//  Created by bob on 2019/8/25.
//

#import "BDTuringSandBoxHelper.h"
#import "NSDictionary+BDTuring.h"

@implementation BDTuringSandBoxHelper

+ (NSString *)appVersion {
    static NSString *versionName = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        versionName = [[[NSBundle mainBundle] infoDictionary] turing_stringValueForKey:@"CFBundleShortVersionString"];;
    });

    return versionName;
}

@end
