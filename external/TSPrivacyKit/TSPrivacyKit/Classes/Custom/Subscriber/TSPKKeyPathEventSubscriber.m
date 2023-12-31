//
//  TSPKKeyPathEventSubscriber.m
//  AWEComplianceImpl-Pods-Aweme
//
//  Created by bytedance on 2021/4/11.
//

#import "TSPKKeyPathEventSubscriber.h"
#import <TSPrivacyKit/TSPKEvent.h>
#import "TSPKLogger.h"
#import "TSPrivacyKitConstants.h"

@implementation TSPKKeyPathEventSubscriber

- (NSString *)uniqueId
{
    return @"TSPKKeyPathEventSubscriber";
}

- (BOOL)canHandelEvent:(TSPKEvent *)event
{
    return YES;
}

- (TSPKHandleResult *_Nullable)hanleEvent:(TSPKEvent *)event
{
    if ([event.params.allKeys count] == 0) {
        return nil;
    }
    // ALog info
    [TSPKLogger logWithTag:TSPKLogCheckTag message:event.params];
    return nil;
}

@end
