//
//  IESFalconManager+InterceptionDelegate.m
//  IESWebKit
//
//  Created by li keliang on 2019/5/7.
//

#import "IESFalconManager+InterceptionDelegate.h"

@implementation IESFalconManager (InterceptionDelegate)

+ (void)callingOutFalconInterceptedRequest:(NSURLRequest *)requst willLoadFromCache:(BOOL)fromCache
{
    if ([IESFalconManager.interceptionDelegate respondsToSelector:@selector(falconInterceptedRequest:willLoadFromCache:)]) {
        [IESFalconManager.interceptionDelegate falconInterceptedRequest:requst willLoadFromCache:fromCache];
    }
}

@end
