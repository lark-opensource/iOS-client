//
//  ACCJSRuntimeContext.m
//
//
//  Created by wanghongyu on 2021/11/7.
//

#import "ACCJSRuntimeContext.h"

@implementation ACCJSRuntimeContext

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static id sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}


@end
