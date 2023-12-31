/**
 * Tencent is pleased to support the open source community by making MLeaksFinder available.
 *
 * Copyright (C) 2017 THL A29 Limited, a Tencent company. All rights reserved.
 *
 * Licensed under the BSD 3-Clause License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 *
 * https://opensource.org/licenses/BSD-3-Clause
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 */

#import "TTMLeakedObjectProxy.h"
#import "TTMLeaksFinder.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import "TTMLeaksFinderJSONRequestSerializer.h"
#import "TTMLLeakContext.h"
#import "TTMLUtils.h"

NSString * const kTTMLeaksFinderLeakNotification = @"kTTMLeaksFinderLeakNotification";

@interface TTMLeakedObjectProxy ()

@property (nonatomic, weak) id object;
@property (nonatomic, strong) TTMLLeakContext *leakContext;

@end

@implementation TTMLeakedObjectProxy

+ (void)addLeakedObject:(id)object {
    NSAssert([NSThread isMainThread], @"Must be in main thread.");
    
    if (![TTMLeaksFinder memoryLeaksConfig]) {
        return; //检查开关
    }
    
    TTMLeakedObjectProxy *proxy = [[TTMLeakedObjectProxy alloc] init];
    proxy.object = object;
    proxy.leakContext = [[TTMLLeakContextMap sharedInstance] ttml_leakContextOf:object];
    
//    static const void * const kLeakedObjectProxyKey = &kLeakedObjectProxyKey;
//    objc_setAssociatedObject(object, kLeakedObjectProxyKey, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if (![TTMLeaksFinder memoryLeaksConfig]) {
            return; //检查开关
        }
        
        if (proxy.object) { //proxy对object的持有是weak，此处double check一下object是否被释放了
            // 每个retaincycle 需要发一次事件，便于解决后在slardar上屏蔽报警
            TTMLLeakContext *leakContext = proxy.leakContext;
            [leakContext.cycles enumerateObjectsUsingBlock:
                ^(TTMLLeakCycle *obj, NSUInteger idx, BOOL *stop) {
                
                NSString *cycleKeyClass = obj.keyClassName;
                NSString *cycleClassName = obj.className;
                
                NSString *cycleID = TTMLMD5String(obj.retainCycle ?: @"");
                NSString *rcIdentifier = TTMLMD5String([NSString stringWithFormat:@"%@ %@",
                                                    [[TTMLeaksFinder memoryLeaksConfig] appVersion] ?: @"",
                                                    obj.retainCycle ?: @""]);
                if (cycleClassName.length > 0) {
                    cycleID = TTMLMD5String(cycleClassName);
                    rcIdentifier = TTMLMD5String([NSString stringWithFormat:@"%@ %@",
                                              [[TTMLeaksFinder memoryLeaksConfig] appVersion] ?: @"",
                                              cycleClassName]);
                }
                
                TTMLeaksCase *leakCase = [[TTMLeaksCase alloc] init];
                leakCase.ID = rcIdentifier;
                leakCase.viewStack = leakContext.viewStack;
                leakCase.retainCycle = obj.retainCycle;
                leakCase.buildInfo = [[TTMLeaksFinder memoryLeaksConfig] buildInfo];
                leakCase.cycleID = cycleID;
                leakCase.cycleKeyClass = cycleKeyClass;
                TTMLeaksConfig *currentConfig = [TTMLeaksFinder memoryLeaksConfig];
                if (currentConfig.userInfoBlock) {
                     leakCase.hostAppUserInfo = currentConfig.userInfoBlock();
                }
                leakCase.appVersion = currentConfig.appVersion;
                leakCase.aid = currentConfig.aid;
                leakCase.mleaksVersion = [TTMLeaksFinder version];
                leakCase.leakCycle = obj;
                
                [self sendLeakNotification:leakCase];
                [self sendLegacyNotification:leakCase];
            }];
        }
    });
}

+ (void)sendLeakNotification:(TTMLeaksCase *)leakCase {
    [[NSNotificationCenter defaultCenter]
        postNotificationName:kTTMLeaksFinderLeakNotification
                      object:leakCase
                    userInfo:nil];
}

#pragma - mark [Legacy Logic]

+ (void)sendLegacyNotification:(TTMLeaksCase *)leakCase {
    NSDictionary *info = [leakCase transToNotificationUserInfo];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTTMLeaksFinderFindMemoryLeakNotification object:nil userInfo:info];
    Class delegateClass = [TTMLeaksFinder memoryLeaksConfig].delegateClass;
    if (delegateClass && [delegateClass respondsToSelector:@selector(leakDidCatched:)]) {
        [[TTMLeaksFinder memoryLeaksConfig].delegateClass leakDidCatched:leakCase];//上报自定义异常
        if ([TTMLeaksFinder memoryLeaksConfig].doubleSend) {
            [TTMLeakedObjectProxy postToLarkRobotWithLeakCase:leakCase];//调用轻服务
        }
    }
    else {
        [TTMLeakedObjectProxy postToLarkRobotWithLeakCase:leakCase];//调用轻服务
    }
}

+ (void)postToLarkRobotWithLeakCase:(TTMLeaksCase *)leakCase {
    static NSMutableArray *sendingIDs;
    if (!sendingIDs) {
        sendingIDs = [NSMutableArray new];
    }
    if ([sendingIDs containsObject:leakCase.ID]) {
        return;//客户端发送频控
    }
    [sendingIDs addObject:leakCase.ID];
    
    NSDictionary *params = [leakCase transToParams];
    [[TTNetworkManager shareInstance] requestForJSONWithResponse:@"https://lt.snssdk.com/leaks_finder/v1/invoke/alert_with_aid" params:params method:@"POST" needCommonParams:NO requestSerializer:[TTMLeaksFinderJSONRequestSerializer class] responseSerializer:nil autoResume:YES callback:^(NSError *error, id obj, TTHttpResponse *response) {
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [sendingIDs removeObject:leakCase.ID];//同一个id，10s内只允许发一次
    });
}

@end

/*
 * 检测到内存泄漏时发出的通知
 * 不再维护，建议使用 kTTMLeaksFinderLeakNotification
 */
__deprecated_msg("use kTTMLeaksFinderLeakNotification instead")
NSString * const kTTMLeaksFinderFindMemoryLeakNotification = @"kMLeaksFinderFindMemoryLeakNotification";
