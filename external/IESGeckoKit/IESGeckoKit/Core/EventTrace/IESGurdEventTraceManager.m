//
//  IESGurdEventTraceManager.m
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/7/4.
//

#import "IESGurdEventTraceManager+Private.h"

#import "IESGeckoDefines.h"

@implementation IESGurdEventTraceManager

#pragma mark - Public

static BOOL kIsGurdEventTraceEnabled = NO;
+ (BOOL)isEnabled
{
    return kIsGurdEventTraceEnabled;
}

+ (void)setEnabled:(BOOL)enabled
{
    kIsGurdEventTraceEnabled = enabled;
}

#pragma mark - Private

+ (IESGurdEventTraceManager *)sharedManager
{
    static IESGurdEventTraceManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

+ (NSString *)formedMessageWithMessage:(NSString *)message
{
    static NSDateFormatter *messageDateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        messageDateFormatter = IESGurdNormalDateFormatter();
    });
    
    NSString *timestampString = [messageDateFormatter stringFromDate:[NSDate date]];
    NSString *threadString = [NSThread isMainThread] ? @"MainThread" : @"Non-MainThread";
    return [NSString stringWithFormat:@"%@ <%@> %@", timestampString, threadString, message];
}

@end
