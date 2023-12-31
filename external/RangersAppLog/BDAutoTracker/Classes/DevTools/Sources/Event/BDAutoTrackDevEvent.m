//
//  BDAutoTrackDevLogger.m
//  RangersAppLog-RangersAppLogDevTools
//
//  Created by bytedance on 2022/10/26.
//

#import <Foundation/Foundation.h>
#import "BDAutoTrack+Private.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackDevToolsHolder.h"
#import "BDAutoTrackDevEvent.h"

@interface BDAutoTrackDevEvent()

@property (nonatomic, strong) NSMapTable<BDAutoTrack *, NSMutableArray<BDAutoTrackDevEventData *> *> *dataMap;
@property (nonatomic, strong) NSMutableDictionary<NSString *, BDAutoTrackDevEventData *> *eventMap;
@property (nonatomic, copy) void(^eventChangeBlock)(BDAutoTrackDevEventData *event);
@property (nonatomic, copy) void(^eventAddBlock)(BDAutoTrackDevEventData *event);

@end

@implementation BDAutoTrackDevEvent

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static BDAutoTrackDevEvent *instance;
    dispatch_once(&onceToken, ^{
        instance = [BDAutoTrackDevEvent new];
        instance.dataMap = [NSMapTable strongToStrongObjectsMapTable];
        instance.eventMap = [NSMutableDictionary new];
    });
    return instance;
}

- (void)bindEvents:(BDAutoTrack *) tracker {
    __weak BDAutoTrackDevEvent *_self = self;
    __weak BDAutoTrack *_tracker = tracker;
    tracker.eventBlock = ^(BDAutoTrackEventStatus eventStatus, BDAutoTrackEventAllType eventType, NSString * _Nonnull eventName, NSDictionary<NSString *,id> * _Nonnull properties) {
        if (!_self) {
            return;
        }
        
//        NSLog(@"event block >>> %@, %@, %@", _tracker, eventName, properties);
        NSMutableArray<BDAutoTrackDevEventData *> *data = [self.dataMap objectForKey:_tracker];
        if (!data) {
            data = [NSMutableArray new];
            [_self.dataMap setObject:data forKey:_tracker];
        }
        
        NSString *trackID = [properties valueForKey:kBDAutoTrackTableColumnTrackID];
        if (!trackID) {
            return;
        }
        
        BDAutoTrackDevEventData *event = [self.eventMap objectForKey:trackID];
        if (event) {
            [event addStatus:eventStatus];
            event.properties = properties;
            if (_self && _self.eventChangeBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _self.eventChangeBlock(event);
                });
            }
        } else {
            event = [BDAutoTrackDevEventData new];
            event.type = eventType;
            event.name = eventName;
            event.properties = properties;
            [event addStatus:eventStatus];
            [data addObject:event];
            if (_self) {
                [_self.eventMap setObject:event forKey:trackID];
                if (_self.eventAddBlock) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        _self.eventAddBlock(event);
                    });
                }
            }
        }
//        NSLog(@"%@ -> type >>> %@ %ld %ld", event.name, event.typeStr, event.type, eventType);
    };
}

- (NSArray<BDAutoTrackDevEventData *> *)getDataByTracker:(BDAutoTrack *)tracker {
    NSMutableArray<BDAutoTrackDevEventData *> *data = [self.dataMap objectForKey:tracker];
    return data ? data : @[];
}

- (void)setEventChangeBlock:(void(^)(BDAutoTrackDevEventData *event)) eventChangeBlock {
    _eventChangeBlock = eventChangeBlock;
}

- (void)setEventAddBlock:(void(^)(BDAutoTrackDevEventData *event)) eventAddBlock {
    _eventAddBlock = eventAddBlock;
}

- (NSArray<BDAutoTrackDevEventData *> *)list {
    BDAutoTrackDevToolsHolder *holder = [BDAutoTrackDevToolsHolder shared];
    NSArray<BDAutoTrackDevEventData *> *list = [self getDataByTracker:holder.tracker];
    return [[list reverseObjectEnumerator] allObjects];
}

- (NSArray<BDAutoTrackDevEventData *> *)search:(NSString *) keyword type:(BDAutoTrackEventAllType) type status:(BDAutoTrackEventStatus) status {
    NSArray<BDAutoTrackDevEventData *> *list = [self list];
    if (keyword && keyword.length) {
        NSPredicate *filter = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@", keyword];
        list = [list filteredArrayUsingPredicate:filter];
    }
    if ([BDAutoTrackDevEventData hasType:type]) {
        NSPredicate *filter = [NSPredicate predicateWithFormat:@"type = %ld", type];
        list = [list filteredArrayUsingPredicate:filter];
    }
    if ([BDAutoTrackDevEventData hasStatus:status]) {
        NSPredicate *filter = [NSPredicate predicateWithFormat:@"statusList CONTAINS[cd] %ld", status];
        list = [list filteredArrayUsingPredicate:filter];
    }
    return list;
}

@end
