//
//  TSPKCalendarOfEKEventPipeline.m
//  Musically
//
//  Created by ByteDance on 2022/9/30.
//

#import "TSPKCalendarOfEKEventPipeline.h"
#import <EventKit/EKEvent.h>
#import "NSObject+TSAddition.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation EKEvent (TSPrivacyKitCalendar)

+ (void)tspk_calendar_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKCalendarOfEKEventPipeline class] clazz:self];
}

+ (EKEvent *)tspk_calendar_eventWithEventStore:(EKEventStore *)eventStore
{
    TSPKHandleResult *result = [TSPKCalendarOfEKEventPipeline handleAPIAccess:NSStringFromSelector(@selector(eventWithEventStore:)) className:[TSPKCalendarOfEKEventPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        return nil;
    } else {
        return [self tspk_calendar_eventWithEventStore:eventStore];
    }
}

@end

@implementation TSPKCalendarOfEKEventPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineCalendarOfEKEvent;
}

+ (NSString *)dataType {
    return TSPKDataTypeCalendar;
}

+ (NSString *)stubbedClass
{
  return @"EKEvent";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return @[
        NSStringFromSelector(@selector(eventWithEventStore:))
    ];
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return nil;
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [EKEvent tspk_calendar_preload];
    });
}

@end
