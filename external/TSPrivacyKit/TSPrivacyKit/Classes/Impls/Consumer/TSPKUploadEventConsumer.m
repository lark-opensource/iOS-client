//
//  TSPKNpthConsumer.m
//  MT-Test
//
//  Created by admin on 2021/12/7.
//

#import "TSPKUploadEventConsumer.h"
#import "TSPKUploadEvent.h"
#import "TSPKLogger.h"
#import "TSPrivacyKitConstants.h"
#import <PNSServiceKit/PNSServiceCenter.h>
#import <PNSServiceKit/PNSUserExceptionProtocol.h>
#import "TSPKHostEnvProtocol.h"

@implementation TSPKUploadEventConsumer

- (NSString *)tag {
    return TSPKEventTagBadcase;
}

- (void)consume:(TSPKBaseEvent *)event {
    if (![event isKindOfClass:[TSPKUploadEvent class]]) return;
    TSPKUploadEvent *uploadEvent = (TSPKUploadEvent *)event;
    // add Event Name
    uploadEvent.filterParams[@"EventName"] = uploadEvent.eventName;
    uploadEvent.filterParams[@"message"] = [NSString stringWithFormat:@"PnS-%@", uploadEvent.params[TSPKPermissionTypeKey]];
    
    id<TSPKHostEnvProtocol> hostEnvProtocol = PNS_GET_INSTANCE(TSPKHostEnvProtocol);
    if ([hostEnvProtocol respondsToSelector:@selector(eventPrefix)]) {
        NSString *eventPrefix = [hostEnvProtocol eventPrefix];
        if (eventPrefix != nil) {
            uploadEvent.eventName = [NSString stringWithFormat:@"%@-%@", eventPrefix, uploadEvent.eventName];
            uploadEvent.params[TSPKMonitorSceneKey] = [NSString stringWithFormat:@"%@-%@", eventPrefix, uploadEvent.params[TSPKMonitorSceneKey]];
            uploadEvent.filterParams[TSPKMonitorSceneKey] = [NSString stringWithFormat:@"%@-%@", eventPrefix, uploadEvent.filterParams[TSPKMonitorSceneKey]];
        }
    }
    
    [PNS_GET_INSTANCE(PNSUserExceptionProtocol) trackUserExceptionWithType:uploadEvent.eventName
                                                       backtracesArray:uploadEvent.backtraces
                                                          customParams:uploadEvent.params
                                                               filters:[self getValidFilters:uploadEvent.filterParams]
                                                              callback:^(NSError * _Nullable error) {
        [TSPKLogger logWithTag:TSPKLogCommonTag message:[NSString stringWithFormat:@"%@ event upload params:%@", uploadEvent.eventName, uploadEvent.params]];
        
        if(!error){
            [TSPKLogger logWithTag:TSPKLogCommonTag message:[NSString stringWithFormat:@"%@ event upload success", uploadEvent.eventName]];
            // report action
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                // upload alog if event contains parameter upload_alog
                if (uploadEvent.isALogUpload) {
                    if ([uploadEvent uploadALogNeedDelay]) {
                        [TSPKLogger reportALog];
                    } else {
                        [TSPKLogger reportALogWithoutDelay];
                    }
                }
            });
        } else {
            [TSPKLogger logWithTag:TSPKLogCommonTag message:[NSString stringWithFormat:@"%@ event upload failed error:%@", uploadEvent.eventName, error]];
        }
    }];
}

- (NSDictionary *)getValidFilters:(NSDictionary *)filters {
    NSMutableDictionary *validFilters = [NSMutableDictionary new];
    [filters enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key isKindOfClass:[NSString class]] && [obj isKindOfClass:[NSString class]]) {
            [validFilters setValue:obj forKey:key];
        } else {
            if ([key isKindOfClass:[NSNumber class]]) {
                key = [(NSNumber *)key stringValue];
            }
            else {
                key = [key description];
            }
            
            if ([obj isKindOfClass:[NSNumber class]]) {
                obj = [(NSNumber *)obj stringValue];
            }
            else {
                obj = [obj description];
            }
            
            [validFilters setValue:obj forKey:key];
        }
    }];
    
    return validFilters.copy;
}

@end
