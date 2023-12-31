//
//  TSPKNetworkReporter.m
//  Musically
//
//  Created by admin on 2022/10/18.
//

#import "TSPKNetworkReporter.h"
#import "TSPKStatisticEvent.h"
#import "TSPKReporter.h"
#import "TSPKLogger.h"
#import "TSPrivacyKitConstants.h"
#import "TSPKAppLifeCycleObserver.h"
#import "TSPKUtils.h"
#import "TSPKNetworkConfigs.h"
#import "TSPKNetworkHostEnvProtocol.h"
#import "TSPKNetworkEvent.h"
#import "TSPKNetworkUtil.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <PNSServiceKit/PNSServiceCenter.h>

@implementation TSPKNetworkReporter

+ (void)reportWithCommonInfo:(NSDictionary *)dict networkEvent:(TSPKNetworkEvent *)networkEvent {
    NSMutableDictionary *category = [NSMutableDictionary dictionary];
    [category setValue:@([[TSPKAppLifeCycleObserver sharedObserver] isAppBackground]) forKey:@"is_background"];
    [category setValue:[[TSPKAppLifeCycleObserver sharedObserver] getCurrentPage] forKey:@"current_page"];
    
    Class clazz = PNS_GET_CLASS(TSPKNetworkHostEnvProtocol);
    if ([clazz respondsToSelector:@selector(otherInformationFromRequest:)]) {
        [category addEntriesFromDictionary:[clazz otherInformationFromRequest:networkEvent.request]];
    }
        
    [category addEntriesFromDictionary:dict];
    
    // common block info
    if ([clazz respondsToSelector:@selector(commonDropUploadInfoByKeys)]) {
        [[clazz commonDropUploadInfoByKeys] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [category removeObjectForKey:obj];
        }];
    }
    
    // custom block info
    [[TSPKNetworkConfigs reportBlockList] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            [category removeObjectForKey:obj];
        }
    }];
    
    NSString *url = [category btd_stringValueForKey:@"url"];
    if (url) {
        [category setValue:[TSPKNetworkUtil URLStringWithoutQuery:url] forKey:@"url"];
    }
    
    NSString *res_url = [category btd_stringValueForKey:@"res_url"];
    if (url) {
        [category setValue:[TSPKNetworkUtil URLStringWithoutQuery:res_url] forKey:@"res_url"];
    }
    
    // move category keys to extrainfo
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    if ([clazz respondsToSelector:@selector(moveValue2ExtraInfoByKeys)]) {
        [[clazz moveValue2ExtraInfoByKeys] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            id value = category[obj];
            if (value) {
                [attributes setValue:value forKey:obj];
                [category removeObjectForKey:obj];
            }
        }];
    }
    
    TSPKStatisticEvent *event = [TSPKStatisticEvent new];
    event.serviceName = @"pns_network";
    event.category = category;
    event.attributes = attributes;
    
    [[TSPKReporter sharedReporter] report:event];
//    [TSPKLogger logWithTag:@"NetworkUploader" message:[NSString stringWithFormat:@"category: %@", event.category]];
//    [TSPKLogger logWithTag:@"NetworkUploader" message:[NSString stringWithFormat:@"attributes: %@", event.attributes]];
}

+ (void)perfWithName:(NSString *)name calledTime:(NSTimeInterval)calledTime {
    [self perfWithName:name calledTime:calledTime networkEvent:nil];
}

+ (void)perfWithName:(NSString *)name calledTime:(NSTimeInterval)calledTime networkEvent:(TSPKNetworkEvent *)networkEvent {
    if (name == nil) return;
    if (networkEvent != nil && [TSPKNetworkConfigs isAllowEvent:networkEvent]) return;
    NSString *finalName = [NSString stringWithFormat:@"%@_cost", name];
    TSPKStatisticEvent *event = [TSPKStatisticEvent initWithMethodName:finalName startedTime:calledTime];
    [[TSPKReporter sharedReporter] report:event];
}

@end
