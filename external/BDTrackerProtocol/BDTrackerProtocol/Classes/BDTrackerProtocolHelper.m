//
//  BDTrackerProtocolHelper.m
//  Pods
//
//  Created by bob on 2020/3/20.
//

#import "BDTrackerProtocolHelper.h"
#import <objc/runtime.h>
#import <objc/message.h>

static NSString * const kBDTrackerProtocolHelperABConfig = @"kBDTrackerProtocolHelperABConfig";

@implementation BDTrackerProtocolHelper

+ (Class)trackerCls {
    static Class clazz = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([BDTrackerProtocolHelper trackerType] == kTrackerTypeBDtracker) {
            clazz = [BDTrackerProtocolHelper bdtrackerCls];
        } else {
            clazz = [BDTrackerProtocolHelper tttrackerCls];
        }
    });
    
    return clazz;
}

+ (Class)bdtrackerCls {
    static Class clazz = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        clazz = NSClassFromString(@"BDTrackerSDK");
    });
    
    return clazz;
}

+ (Class)tttrackerCls {
    static Class clazz = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        clazz = NSClassFromString(@"TTTracker");
    });
    
    return clazz;
}

/// if you config trackerType，will work according to trackerType
/// default is TT，but if TT not exist，use BD
+ (kTrackerType)trackerType {
    /// work only once when launching
    static kTrackerType type = kTrackerTypeTTTracker;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        type = [[NSUserDefaults standardUserDefaults] integerForKey:kBDTrackerProtocolHelperABConfig];
        /// use BD if TT not exist
        if (type == kTrackerTypeBDtracker && [BDTrackerProtocolHelper bdtrackerCls] == nil) {
            type = kTrackerTypeTTTracker;
        }
        ///use TT if BD not exist
        if (type != kTrackerTypeBDtracker && [BDTrackerProtocolHelper tttrackerCls] == nil) {
            type = kTrackerTypeBDtracker;
        }
    });
    
    return type;
}

 /// work for next launch
+ (void)setTrackerType:(kTrackerType)type {
    [[NSUserDefaults standardUserDefaults] setInteger:type forKey:kBDTrackerProtocolHelperABConfig];
}

@end
