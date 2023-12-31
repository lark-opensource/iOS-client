//
//  BDXBridgeCalendarManager+BDXBridgeSecure.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/4/20.
//

#import "BDXBridgeCalendarManager+BDXBridgeSecure.h"
#import "BDXBridgeGetCalendarEventMethod.h"
#import "BDXBridgeMacros.h"
#import <EventKit/EKEventStore.h>
#import <EventKit/EKCalendar.h>
#import <EventKit/EKEvent.h>
#import <EventKit/EKAlarm.h>

@implementation BDXBridgeCalendarManager (BDXBridgeSecure)

- (void)readEventWithEventID:(NSString *)eventID completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    [self requestAccessWithActionHandler:^{
        EKEvent *event = [self.eventStore eventWithIdentifier:eventID];
        if (event) {
            BDXBridgeGetCalendarEventMethodResultModel *resultModel = [BDXBridgeGetCalendarEventMethodResultModel new];
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

@end
