//
//  BDAutoTrackPageLeave.m
//  RangersAppLog
//
//  Created by bytedance on 2022/4/9.
//

#import <Foundation/Foundation.h>
#import "BDAutoTrackDurationEvent.h"
#import "BDAutoTrackUtility.h"
#import "RangersLog.h"
#import "BDUIAutoTracker.h"
#import "BDAutoTrack+Private.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDTrackConstants.h"
#import "BDAutoTrackPageLeave.h"
#import "UIViewController+AutoTrack.h"


@interface BDAutoTrackPageLeave()

@property (nonatomic, strong) BDAutoTrackDurationEvent *currentEvent;
@property (nonatomic, strong) NSMapTable *eventDict;

@end



@implementation BDAutoTrackPageLeave

#pragma mark - init

+ (instancetype)shared {
    static BDAutoTrackPageLeave *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    
    return sharedInstance;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    
    self.enabled = NO;
    self.eventDict = [NSMapTable weakToStrongObjectsMapTable];
    
    [self bindevents];

    return self;
}


#pragma mark - events

- (void)bindevents {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onWillEnterForeground) name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)onDidEnterBackground {
    if (self.enabled && self.currentEvent != nil) {
        NSNumber * nowTimeMS = bd_milloSecondsInterval();
        [self.currentEvent pause:nowTimeMS];
    }
}

- (void)onWillEnterForeground {
    if (self.enabled && self.currentEvent != nil) {
        NSNumber * nowTimeMS = bd_milloSecondsInterval();
        [self.currentEvent resume:nowTimeMS];
    }
}


#pragma mark - implementations

- (void)enterPage:(UIViewController *)vc {
    @try {
        //    NSMutableDictionary *pageInfo = [vc bd_pageTrackInfo];
        //    NSLog(@">>> call enterPage: %@", pageInfo[@"page_title"]);
        if (![self checkEnabled]) {
            return;
        }
        if (![self isPage:vc]) {
            return;
        }
        
        NSString *version = [UIDevice currentDevice].systemVersion;
        if (version.doubleValue > 10.0) {
            NSNumber * nowTimeMS = bd_milloSecondsInterval();
            NSString * eventName = [NSString stringWithFormat:@"bdautotrack_leave_page_event_%lu", vc.hash];
            self.currentEvent = [BDAutoTrackDurationEvent createByEventName:eventName];
            [self.currentEvent start:nowTimeMS];
            [self.eventDict setObject:self.currentEvent forKey:vc];
        }
    } @catch (NSException *exception) {}
}

- (void)leavePage:(UIViewController *)vc {
    @try {
        //    NSMutableDictionary *pageInfo = [vc bd_pageTrackInfo];
//            NSLog(@">>> call leavePage: %@", pageInfo[@"page_title"]);
        if (!self.enabled) {
            return;
        }
        
        NSMutableDictionary *params = [NSMutableDictionary new];
        NSString *version = [UIDevice currentDevice].systemVersion;
        if (version.doubleValue > 10.0) {
            BDAutoTrackDurationEvent *durationEvent = [self getEventByController:vc];
            if (durationEvent == nil || durationEvent.state == BDAutoTrackDurationEventStop) {
                return;
            }

            NSNumber * nowTimeMS = bd_milloSecondsInterval();
            [durationEvent stop:nowTimeMS];
            [params setValue:[NSNumber numberWithLong:durationEvent.duration] forKey:kBDAutoTrackEventPageDuration];
            [self.eventDict removeObjectForKey:vc];
            bd_ui_trackPageLeaveEvent(vc, params);
        }
    } @catch (NSException *exception) {}
}


#pragma mark - private functions

- (BOOL)isPage:(UIViewController *)vc {
    if (vc) {
        CGRect screenFrame = [UIScreen mainScreen].bounds;
        CGRect frame = vc.view.frame;
        return screenFrame.size.width <= frame.size.width && screenFrame.size.height <= frame.size.height;
    }
    return NO;
}

- (BDAutoTrackDurationEvent *)getEventByController:(UIViewController *)vc {
    if (!vc) {
        return nil;
    }
    return [self.eventDict objectForKey:vc];
}

- (BOOL)checkEnabled {
    NSArray<BDAutoTrack *> *allTracker = [BDAutoTrack allTrackers];
    for (BDAutoTrack *track in allTracker) {
        if (![track isKindOfClass:[BDAutoTrack class]]) {
            continue;
        }
        BDAutoTrackLocalConfigService *settings = track.localConfig;
        if (settings.trackPageLeaveEnabled) {
            self.enabled = YES;
            return YES;
        }
    }
    self.enabled = NO;
    return NO;
}

@end
