//
//  TSPKAccessEntrySubscriber.m
//  AWEComplianceImpl-Pods-Aweme
//
//  Created by bytedance on 2021/4/11.
//

#import "TSPKAccessEntrySubscriber.h"
#import "TSPKUtils.h"
#import <TSPrivacyKit/TSPKEvent.h>
#import "TSPKLogger.h"
#import "TSPrivacyKitConstants.h"
#import "TSPKAppLifeCycleObserver.h"

@interface TSPKAccessEntrySubscriber ()
@property(atomic, strong)NSString *appstatus;//make sure it is modified by atomic to ensure thread safe

@end

@implementation TSPKAccessEntrySubscriber

- (instancetype)init
{
    if (self = [super init]) {
        self.appstatus = @"Foreground";
        [self startObserverAppStatus];
    }
    return self;
}

- (NSString *)uniqueId
{
    return @"TSPKAccessEntrySubscriber";
}

- (BOOL)canHandelEvent:(TSPKEvent *)event
{
    return YES;
}

- (TSPKHandleResult *_Nullable)hanleEvent:(TSPKEvent *)event
{
    NSString *appstatusUpdate = [TSPKUtils appStatusWithDefault:nil];
    TSPKEventData *eventData = event.eventData;
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *instanceInfo = [[NSMutableDictionary alloc] init];
    if (eventData.matchedRuleId != 0) {
        [dict setObject:@(eventData.matchedRuleId) forKey:@"ruleId"];
    }
    
    [dict setObject:@"apiCall" forKey:@"type"];
    [dict setObject:eventData.topPageName?:@"nil" forKey:@"topPageName"];
    
    [dict setObject:appstatusUpdate?:self.appstatus forKey:@"appstatus"];
    
    if (eventData.apiModel.pipelineType) {
        [dict setObject:eventData.apiModel.pipelineType forKey:@"channel"];
    }
    
    if (eventData.apiModel.hashTag && [eventData.apiModel.hashTag isKindOfClass:[NSString class]] && ![eventData.apiModel.hashTag isEqualToString:@""]) {
        [instanceInfo setObject:eventData.apiModel.hashTag forKey:@"address"];
    }
    
    if (eventData.apiModel.apiMethod) {
        [instanceInfo setObject:[TSPKUtils concateClassName:event.eventData.apiModel.apiClass method:event.eventData.apiModel.apiMethod] forKey:@"callMethod"];
    }
    
    [instanceInfo setObject:@(eventData.unixTimestamp) forKey:@"timestamp"];
    
    [dict setObject:instanceInfo forKey:@"instanceInfo"];

    [TSPKLogger logWithTag:TSPKLogCheckTag message:dict];

    return nil;
}

#pragma mark -
- (void)startObserverAppStatus {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationBecomeActive)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationBecomeInactive)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

- (void)applicationBecomeActive {
    self.appstatus = @"Foreground";
}

- (void)applicationBecomeInactive {
    self.appstatus = @"Background";
}

@end
