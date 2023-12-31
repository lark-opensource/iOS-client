//
//  BDABTestExposureManager.m
//  ABSDKDemo
//
//  Created by bytedance on 2018/7/24.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "BDABTestExposureManager.h"
#import "BDABTestManager+Private.h"
#import "BDABTestManager+Cache.h"
#import <BDTrackerProtocol/BDTrackerProtocol.h>

static NSString *const BDABTestExposureUserDefaultsKey = @"ABTestExposureUserDefaultsKey";

@interface BDABTestExposureManager () {
    NSRecursiveLock *vidLock;
    NSMutableArray *triggerdVids;
}

@property (nonatomic, strong) NSMutableSet<NSString *> *exposedVids;

@end

@implementation BDABTestExposureManager

- (void)dealloc {
    vidLock = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)sharedManager {
    static BDABTestExposureManager *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [self new];
    });
    return sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        triggerdVids = [NSMutableArray array];
        vidLock = [NSRecursiveLock new];
        NSString *string = [self exposureVidString];
        self.exposedVids = [[NSMutableSet alloc] initWithArray:[string componentsSeparatedByString:@","]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateExposureVidString) name:kBDABTestResultUpdatedNotificaion object:nil];
        self.eventEnabled = YES;
        //exposure for default
        [self sendExposureEvent:nil];
    }
    return self;
}

- (void)exposeVid:(NSNumber *)vid {
    if (!vid) {
        return;
    }
    [vidLock lock];
    BOOL contain = [self.exposedVids containsObject:[vid stringValue]];
    [vidLock unlock];
    
    BOOL eventEnabled = YES;
    if (!contain) {
        [vidLock lock];
        [self.exposedVids addObject:[vid stringValue]];
        if ([triggerdVids containsObject:[vid stringValue]]) {
            eventEnabled = NO;
        } else {
            [triggerdVids addObject:[vid stringValue]];
        }
        [vidLock unlock];
        [self updateExposureVidString];
    }
    if (eventEnabled) {
        [self sendExposureEvent:vid];
    }
}

- (void)sendExposureEvent:(NSNumber *)exposedVid
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setValue:@"abtest_ab_sdk" forKey:@"params_for_special"];
    if (exposedVid) {
        [parameters setValue:[exposedVid stringValue] forKey:@"trigger_vid"];
    }
    NSString *ab_sdk_version = nil;
    [vidLock lock];
    ab_sdk_version = [[self.exposedVids allObjects] componentsJoinedByString:@","];
    [vidLock unlock];
    [parameters setValue:ab_sdk_version?:@"" forKey:@"ab_sdk_version"];
    [BDTrackerProtocol eventV3:@"abtest_ab_sdk_vid_exposure" params:parameters];
}

- (NSRecursiveLock *)_vidLock {
    return vidLock;
}

- (void)updateExposureVidString {
    NSSet<NSString *> *validVids = [[BDABTestManager sharedManager] validVids];
    if ([self isKindOfClass:NSClassFromString(@"BDCommonABTestExposureManager")]) {
        BDABTestExposureManager *exposureManager = [BDABTestExposureManager sharedManager];
        [exposureManager._vidLock lock];
        [exposureManager.exposedVids intersectSet:validVids];
        NSString *exposedVidString = [[exposureManager.exposedVids allObjects] componentsJoinedByString:@","];
        [exposureManager._vidLock unlock];
        [[NSUserDefaults standardUserDefaults] setObject:exposedVidString forKey:BDABTestExposureUserDefaultsKey];
    } else {
        [vidLock lock];
        [self.exposedVids intersectSet:validVids];
        NSString *exposedVidString = [[self.exposedVids allObjects] componentsJoinedByString:@","];
        [vidLock unlock];
        [[NSUserDefaults standardUserDefaults] setObject:exposedVidString forKey:BDABTestExposureUserDefaultsKey];
    }
}

- (NSString *)exposureVidString {
    return [[NSUserDefaults standardUserDefaults] stringForKey:BDABTestExposureUserDefaultsKey];
}

@end
