//
//  PushSDKTracker.m
//  LarkTracker
//
//  Created by 李晨 on 2019/12/5.
//

#import <Foundation/Foundation.h>
#import "PushSDKTracker.h"

@implementation PushSDKTrackerProvider
+ (instancetype)shared {
    static PushSDKTrackerProvider *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      shared = [[PushSDKTrackerProvider alloc] init];
    });
    return shared;
}
@end
