//
//  LKNativeAppExtension.m
//  LKNativeAppExtension
//
//  Created by Bytedance on 2021/12/17.
//

#import <LKNativeAppExtension/LKNativeAppExtension.h>

@implementation LKNativeAppExtension

- (instancetype)init {
    if ( self = [super init]) {
        // do inital
    }
    return self;
}

- (void)destroy {}

- (NSString * _Nonnull )appId {
    return  @"";
}

@end
