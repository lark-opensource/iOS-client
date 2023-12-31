//
//  BDXBridgeCalendarManager.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/9.
//

#import "BDXBridgeCalendarManager.h"
#import "BDXBridgeSetCalendarEventMethod.h"
#import "BDXBridgeMacros.h"
#import "BDXBridgeCreateCalendarEventMethod.h"
#import "BDXBridgeReadCalendarEventMethod.h"
#import <EventKit/EventKit.h>

@interface BDXBridgeCalendarManager ()

@property (nonatomic, strong) EKEventStore *eventStore;

@property (nonatomic, strong) NSUserDefaults *userDefaults;

@end

@implementation BDXBridgeCalendarManager

+ (instancetype)sharedManager
{
    static BDXBridgeCalendarManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [BDXBridgeCalendarManager new];
    });
    return manager;
}

- (void)createEventWithParamModel:(BDXBridgeSetCalendarEventMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    if (!paramModel.startDate || !paramModel.endDate) {
        BDXBridgeStatus *status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"Parameter 'startDate' & 'endDate' should not be empty."];
        bdx_invoke_block(completionHandler, nil, status);
        return;
    }
    
    [self requestAccessWithActionHandler:^{
        NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:([paramModel.startDate doubleValue] / 1000)];
        NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:([paramModel.endDate doubleValue] / 1000)];
        EKAlarm *alarm = [EKAlarm alarmWithRelativeOffset:([paramModel.alarmOffset doubleValue] / -1000)];
        
        // Find calendar to add event.
        __block EKCalendar *calendar = self.eventStore.defaultCalendarForNewEvents;
        if (!calendar) {
            NSArray<EKCalendar *> *calendars = [self.eventStore calendarsForEntityType:EKEntityTypeEvent];
            [calendars enumerateObjectsUsingBlock:^(EKCalendar *obj, NSUInteger idx, BOOL *stop) {
                if (calendar.type == EKCalendarTypeLocal || calendar.type == EKCalendarTypeCalDAV) {
                    calendar = obj;
                    *stop = YES;
                }
            }];
        }
        if (!calendar) {
            BDXBridgeStatus *status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeNotFound message:@"Failed to create event due to no calendar found."];
            bdx_invoke_block(completionHandler, nil, status);
            return;
        }
        
        // Check whether there's any duplicated event.
        NSPredicate *predicate = [self.eventStore predicateForEventsWithStartDate:startDate endDate:endDate calendars:@[calendar]];
        __block EKEvent *duplicatedEvent = nil;
        [self.eventStore enumerateEventsMatchingPredicate:predicate usingBlock:^(EKEvent *event, BOOL *stop) {
            if (paramModel.allDay == event.isAllDay &&
                [startDate isEqualToDate:event.startDate] &&
                [endDate isEqualToDate:event.endDate] &&
                [self leftString:paramModel.title isEqualToRightString:event.title] &&
                [self leftString:paramModel.notes isEqualToRightString:event.notes] &&
                [self leftString:paramModel.location isEqualToRightString:event.location] &&
                [self leftString:paramModel.url isEqualToRightString:event.URL.absoluteString] &&
                alarm.relativeOffset == event.alarms.firstObject.relativeOffset) {
                duplicatedEvent = event;
                *stop = YES;
            }
        }];
        if (duplicatedEvent) {
            BDXBridgeStatus *status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeAlreadyExists message:@"The event with eventID '%@' has already existed.", duplicatedEvent.eventIdentifier];
            BDXBridgeSetCalendarEventMethodResultModel *resultModel = [BDXBridgeSetCalendarEventMethodResultModel new];
            resultModel.eventID = duplicatedEvent.eventIdentifier;
            bdx_invoke_block(completionHandler, resultModel, status);
            return;
        }
        
        // Create and save a new event.
        EKEvent *event = [EKEvent eventWithEventStore:self.eventStore];
        event.calendar = calendar;
        event.startDate = startDate;
        event.endDate = endDate;
        if (alarm) {
            [event addAlarm:alarm];
        }
        event.title = paramModel.title;
        event.notes = paramModel.notes;
        event.allDay = paramModel.allDay;
        event.location = paramModel.location;
        event.URL = [NSURL URLWithString:paramModel.url];

        NSError *error = nil;
        BDXBridgeStatus *status = nil;
        BDXBridgeSetCalendarEventMethodResultModel *resultModel = nil;
        [self.eventStore saveEvent:event span:EKSpanThisEvent commit:YES error:&error];
        if (error) {
            status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeFailed message:@"Failed to create event: %@.", error.localizedDescription];
        } else {
            resultModel = [BDXBridgeSetCalendarEventMethodResultModel new];
            resultModel.eventID = event.eventIdentifier;
        }
        bdx_invoke_block(completionHandler, resultModel, status);
    } completionHandler:completionHandler];
}

- (void)updateEventWithParamModel:(BDXBridgeSetCalendarEventMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    [self requestAccessWithActionHandler:^{
        EKEvent *event = [self.eventStore eventWithIdentifier:paramModel.eventID];
        BDXBridgeStatus *status = nil;
        if (event) {
            EKAlarm *alarm = [EKAlarm alarmWithRelativeOffset:([paramModel.alarmOffset doubleValue] / -1000)];
            event.startDate = [NSDate dateWithTimeIntervalSince1970:([paramModel.startDate doubleValue] / 1000)];
            event.endDate = [NSDate dateWithTimeIntervalSince1970:([paramModel.endDate doubleValue] / 1000)];
            if (alarm) {
                [event addAlarm:alarm];
            }
            event.title = paramModel.title;
            event.notes = paramModel.notes;
            event.allDay = paramModel.allDay;
            event.location = paramModel.location;
            event.URL = [NSURL URLWithString:paramModel.url];

            NSError *error = nil;
            [self.eventStore saveEvent:event span:EKSpanThisEvent commit:YES error:&error];
            if (error) {
                status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeFailed message:@"Failed to update event: %@.", error.localizedDescription];
            }
        } else {
            status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"The event with eventID '%@' doesn't exist.", paramModel.eventID];
        }
        bdx_invoke_block(completionHandler, nil, status);
    } completionHandler:completionHandler];
}

- (void)deleteEventWithEventID:(NSString *)eventID completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    [self requestAccessWithActionHandler:^{
        EKEvent *event = [self.eventStore eventWithIdentifier:eventID];
        BDXBridgeStatus *status = nil;
        if (event) {
            NSError *error = nil;
            [self.eventStore removeEvent:event span:EKSpanThisEvent commit:YES error:&error];
            status = error ? [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeFailed message:error.localizedDescription] : nil;
        } else {
            status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"The event with eventID '%@' doesn't exist.", eventID];
        }
        bdx_invoke_block(completionHandler, nil, status);
    } completionHandler:completionHandler];
}

- (EKEventStore *)eventStore
{
    if (!_eventStore) {
        _eventStore = [EKEventStore new];
    }
    return _eventStore;
}

- (NSUserDefaults *)userDefaults
{
    if (!_userDefaults) {
        _userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"BDXBridgeCalendarStorage"];
    }
    
    return _userDefaults;
}

#pragma mark - Other version API

- (void)createEventWithBizParamModel:(BDXBridgeCreateCalendarEventMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    if (!paramModel.startDate || !paramModel.endDate) {
        BDXBridgeStatus *status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"Parameter 'startDate' & 'endDate' should not be empty."];
        bdx_invoke_block(completionHandler, nil, status);
        return;
    }

    [self requestAccessWithActionHandler:^{
        NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:([paramModel.startDate doubleValue] / 1000)];
        NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:([paramModel.endDate doubleValue] / 1000)];
        EKAlarm *alarm = [EKAlarm alarmWithRelativeOffset:([paramModel.alarmOffset doubleValue] / -1000)];
        
        // Find calendar to add event.
        __block EKCalendar *calendar = self.eventStore.defaultCalendarForNewEvents;
        if (!calendar) {
            NSArray<EKCalendar *> *calendars = [self.eventStore calendarsForEntityType:EKEntityTypeEvent];
            [calendars enumerateObjectsUsingBlock:^(EKCalendar *obj, NSUInteger idx, BOOL *stop) {
                if (calendar.type == EKCalendarTypeLocal || calendar.type == EKCalendarTypeCalDAV) {
                    calendar = obj;
                    *stop = YES;
                }
            }];
        }
        if (!calendar) {
            BDXBridgeStatus *status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeNotFound message:@"Failed to create event due to no calendar found."];
            bdx_invoke_block(completionHandler, nil, status);
            return;
        }
        
        NSString *eventID = [self.userDefaults stringForKey:paramModel.identifier];
        
        EKEvent *event = [self.eventStore eventWithIdentifier:eventID];
        
        BOOL created = NO;
        BOOL isRepeatEvent = NO;
        
        if (event) {
            created = YES;
            isRepeatEvent = event.hasRecurrenceRules;
        } else {
            // Create and save a new event.
            event = [EKEvent eventWithEventStore:self.eventStore];
        }
        
        event.calendar = calendar;
        event.startDate = startDate;
        event.endDate = endDate;
        if (alarm) {
            [event addAlarm:alarm];
        }
        event.title = paramModel.title;
        event.notes = paramModel.notes;
        event.allDay = paramModel.allDay;
        event.location = paramModel.location;
        event.URL = [NSURL URLWithString:paramModel.url];
        
        EKRecurrenceRule *rule = nil;
        
        if (paramModel.repeatCount > 0
            && paramModel.repeatInterval > 0) {
            EKRecurrenceEnd *ruleEnd = [EKRecurrenceEnd recurrenceEndWithOccurrenceCount:paramModel.repeatCount];
            rule = [[EKRecurrenceRule alloc] initRecurrenceWithFrequency:(EKRecurrenceFrequency)paramModel.repeatFrequency
                                                                                  interval:paramModel.repeatInterval
                                                                                       end:ruleEnd];
            isRepeatEvent = YES;
        }
        
        if (rule) {
            event.recurrenceRules = @[rule];
        } else {
            event.recurrenceRules = nil;
        }

        NSError *error = nil;
        BDXBridgeStatus *status = nil;
        [self.eventStore saveEvent:event
                              span:isRepeatEvent ? EKSpanFutureEvents : EKSpanThisEvent
                            commit:YES
                             error:&error];
        if (error) {
            status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeFailed message:@"Failed to create/update event: %@.", error.localizedDescription];
        } else {
            [self.userDefaults setObject:event.eventIdentifier forKey:paramModel.identifier];
            [self.userDefaults synchronize];
        }
        bdx_invoke_block(completionHandler, nil, status);

    } completionHandler:completionHandler];
}

- (void)readEventWithBizID:(NSString *)bizID completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    NSString *eventID = [self.userDefaults stringForKey:bizID];
    
    if (eventID.length == 0) {
        BDXBridgeStatus *status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeNotFound
                                                                message:@"The event with identifier '%@' doesn't exist.", bizID];
        bdx_invoke_block(completionHandler, nil, status);
        return;
    }
    
    [self requestAccessWithActionHandler:^{
        EKEvent *event = [self.eventStore eventWithIdentifier:eventID];
        if (event) {
            BDXBridgeReadCalendarEventMethodResultModel *resultModel = [BDXBridgeReadCalendarEventMethodResultModel new];
            resultModel.startDate = @([event.startDate timeIntervalSince1970] * 1000);
            resultModel.endDate = @([event.endDate timeIntervalSince1970] * 1000);
            if (event.hasAlarms) {
                resultModel.alarmOffset = @(event.alarms.firstObject.relativeOffset * -1000);
            }
            resultModel.title = event.title;
            resultModel.notes = event.notes;
            resultModel.allDay = event.isAllDay;
            resultModel.location = event.location;
            resultModel.url = event.URL.absoluteString;
            bdx_invoke_block(completionHandler, resultModel, nil);
        } else {
            BDXBridgeStatus *status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"The event with eventID '%@' doesn't exist.", eventID];
            bdx_invoke_block(completionHandler, nil, status);
        }
    } completionHandler:completionHandler];
}

- (void)deleteEventWithBizID:(NSString *)bizID completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler;
{
    NSString *eventID = [self.userDefaults stringForKey:bizID];
    
    if (eventID.length == 0) {
        BDXBridgeStatus *status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeNotFound
                                                                message:@"The event with identifier '%@' doesn't exist.", bizID];
        bdx_invoke_block(completionHandler, nil, status);
        return;
    }

    [self requestAccessWithActionHandler:^{
        EKEvent *event = [self.eventStore eventWithIdentifier:eventID];
        BDXBridgeStatus *status = nil;
        if (event) {
            NSError *error = nil;
            [self.userDefaults removeObjectForKey:bizID];
            [self.userDefaults synchronize];
            [self.eventStore removeEvent:event
                                    span:event.hasRecurrenceRules ? EKSpanFutureEvents :EKSpanThisEvent
                                  commit:YES
                                   error:&error];
            status = error ? [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeFailed message:error.localizedDescription] : nil;
        } else {
            status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"The event with eventID '%@' doesn't exist.", eventID];
        }
        bdx_invoke_block(completionHandler, nil, status);
    } completionHandler:completionHandler];
}

#pragma mark - Helpers

- (void)requestAccessWithActionHandler:(dispatch_block_t)actionHandler completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    [self.eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        if (granted) {
            [self.eventStore reset];    // The calendar may not found before reset the event store.
            bdx_invoke_block(actionHandler);
        } else {
            BDXBridgeStatus *status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeUnauthorizedAccess message:@"Accessing to calendar is unauthorized: %@.", error.localizedDescription];
            bdx_invoke_block(completionHandler, nil, status);
        }
    }];
}

- (BOOL)leftString:(NSString *)leftString isEqualToRightString:(NSString *)rightString
{
    return (leftString.length == 0 && rightString.length == 0) || [leftString isEqualToString:rightString];
}

@end
