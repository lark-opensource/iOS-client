//
//  BDAutoTrackDevToolsMonitor.h
//  RangersAppLog
//
//  Created by bytedance on 2022/10/24.
//

#import "BDAutoTrack.h"

FOUNDATION_EXTERN NSString * const kBDAutoTrackDevToolsOpen;
FOUNDATION_EXTERN NSString * const kBDAutoTrackDevToolsClose;
FOUNDATION_EXTERN NSString * const kBDAutoTrackDevToolsTabLog;
FOUNDATION_EXTERN NSString * const kBDAutoTrackDevToolsTabEvent;
FOUNDATION_EXTERN NSString * const kBDAutoTrackDevToolsTabNet;
FOUNDATION_EXTERN NSString * const kBDAutoTrackDevToolsTabInfo;
FOUNDATION_EXTERN NSString * const kBDAutoTrackDevToolsShareLog;
FOUNDATION_EXTERN NSString * const kBDAutoTrackDevToolsSearchLog;
FOUNDATION_EXTERN NSString * const kBDAutoTrackDevToolsSearchEvent;
FOUNDATION_EXTERN NSString * const kBDAutoTrackDevToolsSearchNet;
FOUNDATION_EXTERN NSString * const kBDAutoTrackDevToolsClickLog;
FOUNDATION_EXTERN NSString * const kBDAutoTrackDevToolsClickEvent;
FOUNDATION_EXTERN NSString * const kBDAutoTrackDevToolsClickNet;

@interface BDAutoTrackDevToolsMonitor : NSObject

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, strong) BDAutoTrack *tracker;
@property (nonatomic, strong) BDAutoTrack *selectedTracker;

- (void)updateSelectedTracker:(BDAutoTrack *) selectedTracker;

- (void)track:(NSString *) eventName params:(NSDictionary *)params;

- (void)track:(NSString *) eventName value:(NSString *)value;

- (void)track:(NSString *) eventName;

@end
