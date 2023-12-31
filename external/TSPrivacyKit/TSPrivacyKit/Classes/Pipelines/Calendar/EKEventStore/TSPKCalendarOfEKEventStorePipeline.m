//
//  TSPKCalendarOfEKEventStorePipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/13.
//

#import "TSPKCalendarOfEKEventStorePipeline.h"
#import <EventKit/EKEventStore.h>
#import "NSObject+TSAddition.h"
#import "TSPKUtils.h"
#import "TSPKConfigs.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation EKEventStore (TSPrivacyKitCalendar)

+ (void)tspk_calendar_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKCalendarOfEKEventStorePipeline class] clazz:self];
}

- (void)tspk_calendar_requestAccessToEntityType:(EKEntityType)entityType completion:(EKEventStoreRequestAccessCompletionHandler)completion
{
    if (entityType == EKEntityTypeEvent) {
        NSDictionary *params = @{
            TSPKAPISubTypeKey : TSPKDataTypeCalendar
        };
        TSPKHandleResult *result = [TSPKCalendarOfEKEventStorePipeline handleAPIAccess:NSStringFromSelector(@selector(requestAccessToEntityType:completion:)) className:[TSPKCalendarOfEKEventStorePipeline stubbedClass] params:params];
        if (result.action == TSPKResultActionFuse) {
            if ([[TSPKConfigs sharedConfig] enableCalendarRequestCompletion]) {
                if (completion) {
                    completion(NO, [TSPKUtils fuseError]);
                }
            }
        } else {
            [self tspk_calendar_requestAccessToEntityType:entityType completion:completion];
        }
    } else {
        [self tspk_calendar_requestAccessToEntityType:entityType completion:completion];
    }
}

- (BOOL)tspk_calendar_saveEvent:(EKEvent *)event span:(EKSpan)span commit:(BOOL)commit error:(NSError **)error
{
    TSPKHandleResult *result = [TSPKCalendarOfEKEventStorePipeline handleAPIAccess:NSStringFromSelector(@selector(saveEvent:span:commit:error:)) className:[TSPKCalendarOfEKEventStorePipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        return NO;
    } else {
        return [self tspk_calendar_saveEvent:event span:span commit:commit error:error];
    }
}

- (BOOL)tspk_calendar_removeEvent:(EKEvent *)event span:(EKSpan)span commit:(BOOL)commit error:(NSError **)error
{
    TSPKHandleResult *result = [TSPKCalendarOfEKEventStorePipeline handleAPIAccess:NSStringFromSelector(@selector(removeEvent:span:commit:error:)) className:[TSPKCalendarOfEKEventStorePipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        return NO;
    } else {
        return [self tspk_calendar_removeEvent:event span:span commit:commit error:error];
    }
}

- (nullable EKEvent *)tspk_calendar_eventWithIdentifier:(NSString *)identifier
{
    NSString *method = NSStringFromSelector(@selector(eventWithIdentifier:));
    NSString *className = [TSPKCalendarOfEKEventStorePipeline stubbedClass];
    TSPKHandleResult *result = [TSPKCalendarOfEKEventStorePipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return nil;
    } else {
        return [self tspk_calendar_eventWithIdentifier:identifier];
    }
}

- (NSArray<EKEvent *> *)tspk_calendar_eventsMatchingPredicate:(NSPredicate *)predicate
{
    NSString *method = NSStringFromSelector(@selector(eventsMatchingPredicate:));
    NSString *className = [TSPKCalendarOfEKEventStorePipeline stubbedClass];
    TSPKHandleResult *result = [TSPKCalendarOfEKEventStorePipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return nil;
    } else {
        return [self tspk_calendar_eventsMatchingPredicate:predicate];
    }
}

@end

@implementation TSPKCalendarOfEKEventStorePipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineCalendarOfEKEventStore;
}

+ (NSString *)dataType {
    return TSPKDataTypeCalendar;
}

+ (NSString *)stubbedClass
{
  return @"EKEventStore";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        NSStringFromSelector(@selector(requestAccessToEntityType:completion:)),
        NSStringFromSelector(@selector(saveEvent:span:commit:error:)),
        NSStringFromSelector(@selector(removeEvent:span:commit:error:)),
        NSStringFromSelector(@selector(eventWithIdentifier:)),
        NSStringFromSelector(@selector(eventsMatchingPredicate:))
    ];
}


+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [EKEventStore tspk_calendar_preload];
    });
}

@end
