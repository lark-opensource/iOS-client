//
//  TSPKEventManager.h
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/19.
//

#import <Foundation/Foundation.h>

#import "TSPKSubscriber.h"
#import "TSPKBaseEvent.h"

typedef BOOL (^TSPKSubscriberJudgeBlock)(id<TSPKSubscriber> _Nullable);

@interface TSPKEventManager : NSObject

+ (void)registerSubsciber:(id<TSPKSubscriber> _Nullable)subscriber onEventType:(TSPKEventType)eventType;
+ (void)registerSubsciber:(id<TSPKSubscriber> _Nullable)subscriber onEventType:(TSPKEventType)eventType apiType:(NSString *_Nullable)apiType;
+ (void)registerSubsciber:(id<TSPKSubscriber> _Nullable)subscriber onEventType:(TSPKEventType)eventType apiTypes:(NSArray *_Nullable)apiTypes;

+ (void)unregisterSubsciber:(id<TSPKSubscriber> _Nullable)subscriber onEventType:(TSPKEventType)eventType;
+ (void)unregisterSubsciber:(id<TSPKSubscriber> _Nullable)subscriber onEventType:(TSPKEventType)eventType apiType:(NSString *_Nullable)apiType;
+ (void)unregisterSubsciber:(id<TSPKSubscriber> _Nullable)subscriber onEventType:(TSPKEventType)eventType apiTypes:(NSArray *_Nullable)apiTypes;

+ (void)unregisterSubscribersWithJudgeBlock:(TSPKSubscriberJudgeBlock _Nullable)judgeBlock;

+ (TSPKHandleResult *_Nullable)dispatchEvent:(TSPKBaseEvent *_Nullable)event;

@end


