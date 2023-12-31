//
//  TSPKApiLogSubscriber.m
//  Musically
//
//  Created by ByteDance on 2022/11/17.
//

#import "TSPKApiLogSubscriber.h"
#import <TSPrivacyKit/TSPKEvent.h>
#import "TSPKSignalManager+public.h"

@implementation TSPKApiLogSubscriber

- (NSString *)uniqueId
{
    return @"TSPKApiLogSubscriber";
}

- (BOOL)canHandelEvent:(TSPKEvent *)event
{
    return YES;
}

- (TSPKHandleResult *_Nullable)hanleEvent:(TSPKEvent *)event
{
    TSPKEventData *eventData = event.eventData;
    TSPKAPIModel *apiModel = eventData.apiModel;
    TSPKAPIUsageType usageType = apiModel.apiUsageType;
    NSString *permissionType = apiModel.dataType;
    
    NSString *method = apiModel.apiMethod;
    if (apiModel.apiClass.length > 0) {
        method = [NSString stringWithFormat:@"%@_%@", apiModel.apiClass, method];
    }
    
    NSString *action = @"";
    switch (eventData.ruleEngineAction) {
        case TSPKResultActionFuse:
            action = @" action:fuse";
            break;
        case TSPKResultActionCache:
            action = @" action:cache";
            break;
        default:
            break;
    }
    
    switch (usageType) {
        case TSPKAPIUsageTypeStart:
        case TSPKAPIUsageTypeStop:
        case TSPKAPIUsageTypeDealloc:
        {
            [TSPKSignalManager addPairSignalWithAPIUsageType:usageType
                                              permissionType:permissionType
                                                     content:[NSString stringWithFormat:@"system %@%@", method, action]
                                                    instance:apiModel.hashTag
                                                   extraInfo:nil];
        }
            break;
        case TSPKAPIUsageTypeNotDefined:
            [TSPKSignalManager addSignalWithType:TSPKSignalTypeSystemMethod permissionType:permissionType content:[NSString stringWithFormat:@"system %@%@", method, action]];
            break;
        case TSPKAPIUsageTypeInfo:
            break;
    }
    
    return nil;
}

@end
