//
//  BDAutoTrackFilter.m
//  RangersAppLog
//
//  Created by bob on 2020/6/11.
//

#import "BDAutoTrackFilter.h"
#import "BDAutoTrackMacro.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrackSandBoxHelper.h"
#import "NSDictionary+VETyped.h"

static NSString * const BDTrackerConfigEventList      = @"event_list";
static NSString * const BDTrackerConfigIsBlack        = @"is_block";
static NSString * const BDTrackerConfigEvents         = @"events";
static NSString * const BDTrackerConfigParams         = @"params";
static NSString * const BDTrackerEventFilterPlistFileName = @"event_filter.plist";

@interface BDAutoTrackFilter ()

/// 标记当前Filter的工作模式，为true是黑名单，为false是白名单。
@property (atomic, assign) BOOL isBlockList;
@property (atomic, copy) NSSet<NSString *> *filterEvents;
@property (atomic, copy) NSDictionary<NSString *, NSArray<NSString *> *> *filterParams;

@property (nonatomic, strong) NSString *eventListPath;
@property (nonatomic, strong) dispatch_queue_t ioQueue;

@end

@implementation BDAutoTrackFilter

- (instancetype)initWithAppID:(NSString *)appID {
    self = [super initWithAppID:appID];
    if (self) {
        self.serviceName = BDAutoTrackServiceNameFilter;
        NSString *eventListPath = [bd_trackerLibraryPathForAppID(appID) stringByAppendingPathComponent:BDTrackerEventFilterPlistFileName];
        self.ioQueue = dispatch_queue_create("com.applog.filter", DISPATCH_QUEUE_SERIAL);
        self.eventListPath = eventListPath;
        self.isBlockList = YES;
        self.filterEvents = [NSSet new];
        self.filterParams = @{};
    }
    
    return self;
}

- (void)loadBlockList {
    BDAutoTrackWeakSelf;
    dispatch_async(self.ioQueue, ^{
        BDAutoTrackStrongSelf;
        /// 黑白名单不跨版本使用
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.eventListPath]) {
            NSDictionary *eventList = [NSDictionary dictionaryWithContentsOfFile:self.eventListPath];
            NSString *currentVersion = bd_sandbox_releaseVersion();
            NSString *configVersion = [eventList vetyped_stringForKey:kBDAutoTrackAPPVersion];
            if ([configVersion isEqualToString:currentVersion]) {
                [self updateBlockList:eventList save:NO];
            } else {
                [self clearBlockList];
            }
        }
    });
}

- (void)updateBlockList:(NSDictionary *)eventList save:(BOOL)save {
    if (BDAutoTrackIsEmptyDictionary(eventList)) {
        return;
    }
    
    self.isBlockList = [eventList vetyped_boolForKey:BDTrackerConfigIsBlack];
    NSArray* filterEvents = [eventList vetyped_arrayForKey:BDTrackerConfigEvents] ?: @[];
    self.filterEvents = [NSSet setWithArray:filterEvents];
    self.filterParams = [eventList vetyped_dictionaryForKey:BDTrackerConfigParams];
    if (save) {
        [self saveBlockList:eventList];
    }
}

- (void)saveBlockList:(NSDictionary *)eventList {
    dispatch_async(self.ioQueue, ^{
        NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithDictionary:eventList copyItems:YES];
        [result setValue:bd_sandbox_releaseVersion() forKey:kBDAutoTrackAPPVersion];
        if (@available(iOS 11, *)) {
            [result writeToURL:[NSURL fileURLWithPath:self.eventListPath] error:nil];
        } else {
            [result writeToFile:self.eventListPath atomically:YES];
        }
    });
}

- (void)clearBlockList {
    self.isBlockList = YES;
    self.filterEvents = [NSSet new];
    self.filterParams = @{};
    [[NSFileManager defaultManager] removeItemAtPath:self.eventListPath error:nil];
}

- (NSDictionary *)filterEvents:(NSDictionary *)event {
    // 不存在黑白名单时，正常上报
    NSSet<NSString *> *filterEvents = self.filterEvents;
    NSDictionary<NSString *, NSArray<NSString *> *> *filterParams = self.filterParams;
    if (filterEvents.count < 1 && filterParams.count < 1) {
        return event;
    }
    
    NSString *eventName = [event vetyped_stringForKey:kBDAutoTrackEventType] ?: @"";
    NSDictionary *params = [event vetyped_dictionaryForKey:kBDAutoTrackEventData] ?: @{};
    NSMutableDictionary *newEvent = [event mutableCopy];
    if (self.isBlockList) {
        // 黑名单：若事件名在黑名单中，则整个事件不上报
        if ([filterEvents containsObject:eventName]) {
            return nil;
        }
        
        NSArray<NSString *> *blockedParams = [filterParams vetyped_arrayForKey:eventName];
        if (blockedParams.count > 0) {
            // 黑名单：若事件参数在黑名单中，则相应事件参数不上报
            NSMutableDictionary *newParams = [params mutableCopy];
            for (NSString *aBlockedParam in blockedParams) {
                [newParams setValue:nil forKey:aBlockedParam];
            }
            [newEvent setValue:newParams forKey:kBDAutoTrackEventData];
        }
        
        return [newEvent copy];
    } else {
        // 白名单：只上报 events 中的事件，如果 params 存在，只上报 params 中的某些字段
        if (filterEvents.count > 0 && ![filterEvents containsObject:eventName]) {
            return nil;
        }
        
        NSArray<NSString *> *allowedParams = [filterParams vetyped_arrayForKey:eventName];
        
        if (allowedParams.count > 0) {
            NSMutableDictionary *newParams = [[NSMutableDictionary alloc] init];
            for (NSString *aAllowedParam in allowedParams) {
                [newParams setValue:[params objectForKey:aAllowedParam]
                             forKey:aAllowedParam];
            }
            [newEvent setValue:newParams forKey:kBDAutoTrackEventData];
        }
        
        return [newEvent copy];
    }
}

@end
