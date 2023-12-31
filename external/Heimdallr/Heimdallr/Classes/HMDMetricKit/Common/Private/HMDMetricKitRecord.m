//
//  HMDMetricKitDiagnosticRecord.m
//  AppHost-Heimdallr-Unit-Tests
//
//  Created by ByteDance on 2023/6/11.
//

#import "HMDMetricKitRecord.h"
#import "HMDMacro.h"

CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

@implementation HMDMetricKitRecord

+ (NSString *)tableName {
    return @"metric_kit_diagnostic";
}

- (NSDictionary *)reportDictionary {
    NSMutableDictionary *payload = [NSMutableDictionary new];
    
    if (hermas_enabled() && self.sequenceCode >= 0) {
        [payload setValue:@(self.sequenceCode) forKey:@"sequence_code"];
    }
    
    if (_eventType == HMDMetricKitEventTypeDiagnostic) {
        
        [payload setObject:@"HMDMetricKit" forKey:@"event_type"];
        
        NSAssert(_diagnostic, @"[HMDMetricKitDiagnosticRecord] diagnostic must be non-null.");
        if (_diagnostic) [payload setObject:_diagnostic forKey:@"diagnostic_payload"];
        
        if (_binaryImages) [payload setObject:_binaryImages forKey:@"binaryimage"];
        
        if (_recentAppImages) [payload setObject:_recentAppImages forKey:@"recent_app_image"];
        
        if (_historyAppImageInfo) [payload setObject:_historyAppImageInfo forKey:@"history_app_image_info"];
        
        if (_historyPreAppImageInfo) [payload setObject:_historyPreAppImageInfo forKey:@"history_pre_app_image_info"];
    }
    else if(_eventType == HMDMetricKitEventTypeMetric) {
        
        [payload setObject:@"HMDMetricKitMetric" forKey:@"event_type"];
        
        NSAssert(_metric, @"[HMDMetricKitMetricRecord] metric must be non-null.");
        if (_metric) [payload setObject:_metric forKey:@"metric_payload"];
    }
    
    return [payload copy];
}

@end


