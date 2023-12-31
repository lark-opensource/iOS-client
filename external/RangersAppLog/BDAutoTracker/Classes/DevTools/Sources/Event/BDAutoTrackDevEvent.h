//
//  BDAutoTrackDevEvent.h
//  RangersAppLog
//
//  Created by bytedance on 2022/10/26.
//

#import "BDAutoTrack.h"
#import "BDAutoTrackDevEventData.h"

@interface BDAutoTrackDevEvent : NSObject

+ (instancetype)shared;

- (void)bindEvents:(BDAutoTrack *) tracker;

- (NSArray<BDAutoTrackDevEventData *> *)getDataByTracker:(BDAutoTrack *)tracker;

- (void)setEventChangeBlock:(void(^)(BDAutoTrackDevEventData *event)) eventChangeBlock;

- (void)setEventAddBlock:(void(^)(BDAutoTrackDevEventData *event)) eventAddBlock;


- (NSArray<BDAutoTrackDevEventData *> *)list;

- (NSArray<BDAutoTrackDevEventData *> *)search:(NSString *) keyword type:(BDAutoTrackEventAllType) type status:(BDAutoTrackEventStatus) status;

@end
