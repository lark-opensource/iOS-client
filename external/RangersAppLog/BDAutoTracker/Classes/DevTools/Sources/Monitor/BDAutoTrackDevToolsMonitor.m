//
//  BDAutoTrackDevToolsMonitor.m
//  RangersAppLog
//
//  Created by bytedance on 2022/10/24.
//

#import <Foundation/Foundation.h>
#import "BDAutoTrack+Private.h"
#import "BDAutoTrackDevToolsMonitor.h"

NSString * const kBDAutoTrackDevToolsOpen            = @"devtools_open";
NSString * const kBDAutoTrackDevToolsClose           = @"devtools_close";
NSString * const kBDAutoTrackDevToolsTabLog          = @"devtools_tab_log";
NSString * const kBDAutoTrackDevToolsTabEvent        = @"devtools_tab_event";
NSString * const kBDAutoTrackDevToolsTabNet          = @"devtools_tab_net";
NSString * const kBDAutoTrackDevToolsTabInfo         = @"devtools_tab_info";
NSString * const kBDAutoTrackDevToolsShareLog        = @"devtools_share_log";
NSString * const kBDAutoTrackDevToolsSearchLog       = @"devtools_search_log";
NSString * const kBDAutoTrackDevToolsSearchEvent     = @"devtools_search_event";
NSString * const kBDAutoTrackDevToolsSearchNet       = @"devtools_search_net";
NSString * const kBDAutoTrackDevToolsClickLog        = @"devtools_click_log";
NSString * const kBDAutoTrackDevToolsClickEvent      = @"devtools_click_event";
NSString * const kBDAutoTrackDevToolsClickNet        = @"devtools_click_net";

static NSString *AppId = @"416477";
static NSString *CommonKey = @"key";
static NSString *FromAppIdKey = @"from_app_id";
static NSString *CNVendor = @"";

@implementation BDAutoTrackDevToolsMonitor

- (instancetype)init {
    self = [super init];
    if (self) {
        self.enabled = YES;
        if ([self hasCNVendor]) {
            self.tracker = [self createTracker];
        }
    }
    return self;
}

- (BOOL)hasCNVendor {
    NSArray<BDAutoTrack *> *allTrackers = [BDAutoTrack allTrackers];
    for (BDAutoTrack *track in allTrackers) {
        if ([track.config.serviceVendor isEqualToString:CNVendor]) {
            return YES;
        }
    }
    return NO;
}

- (void)updateSelectedTracker:(BDAutoTrack *) selectedTracker {
    self.selectedTracker = selectedTracker;
}

- (BDAutoTrack *)createTracker {
    BDAutoTrackConfig *config = [BDAutoTrackConfig configWithAppID:AppId launchOptions:nil];
    config.serviceVendor = CNVendor;
    config.monitorEnabled = NO;
    config.autoTrackEnabled = NO;
    config.showDebugLog = NO;
    config.devToolsEnabled = NO;
    BDAutoTrack *tracker = [BDAutoTrack trackWithConfig:config];
    [tracker startTrack];
    return tracker;
}

- (void)track:(NSString *) eventName params:(NSDictionary *)params {
    if (!self.enabled) {
        return;
    }
    
    if (!self.selectedTracker) {
        return;
    }
    
    if (![self.selectedTracker.config.serviceVendor isEqualToString:CNVendor]) {
        return;
    }
    
    NSMutableDictionary *newParams = [NSMutableDictionary new];
    if (!self.tracker) {
        self.tracker = [self createTracker];
    }
    if (params) {
        [newParams addEntriesFromDictionary:params];
    }
    [newParams setValue:self.selectedTracker.appID forKey:FromAppIdKey];
    [self.tracker eventV3:eventName params:newParams];
}

- (void)track:(NSString *) eventName value:(NSString *)value {
    NSMutableDictionary *params = [NSMutableDictionary new];
    [params setValue:value forKey:CommonKey];
    [self track:eventName params:params];
}

- (void)track:(NSString *) eventName {
    [self track:eventName params:nil];
}

@end
