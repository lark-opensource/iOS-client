//
//  IESBridgeMessage+Private.m
//  IESWebKit
//
//  Created by li keliang on 2019/4/11.
//

#import "IESBridgeMessage+Private.h"
#import <objc/runtime.h>

@implementation IESBridgeMessage (Private)

+ (NSString *)generateCurrentTimeString
{
    return [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970] * 1000];
}

@end
