//
//  HMDNetTrafficMonitorRecord.m
//  Heimdallr
//
//  Created by fengyadong on 2018/6/14.
//

#import "HMDNetTrafficMonitorRecord.h"
#import "HMDMacro.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
#import "HMDHermasCounter.h"

HMDNetTrafficFrontType const kHMDNetTrafficFrontTypeForeground = @"front";
HMDNetTrafficFrontType const kHMDNetTrafficFrontTypeFreground = @"front";
HMDNetTrafficFrontType const kHMDNetTrafficFrontTypeBackgroundEverFront = @"bg_ever_front";
HMDNetTrafficFrontType const kHMDNetTrafficFrontTypeBackgroundNeverFront = @"bg_never_front";

@implementation HMDNetTrafficMonitorRecord

+ (instancetype)newRecordWithFrontType:(HMDNetTrafficFrontType)frontType
                               netType:(NSString *)netType {
    HMDNetTrafficMonitorRecord *record = [HMDNetTrafficMonitorRecord newRecord];
    record.netType = netType;
    record.frontType = frontType;
    return record;
}

- (HMDMonitorRecordValue)value {
    return 0;
}

- (NSMutableArray<NSString *> *)exceptionTypes {
    if (!_exceptionTypes) {
        _exceptionTypes = [NSMutableArray array];
    }
    return _exceptionTypes;
}


+ (NSUInteger)cleanupWeight {
    return 40;
}

+ (NSArray *)bg_ignoreKeys {
    return @[@"isCustomSpan"];
}

- (unsigned long long)cellularTenMinusage {
    return self.cellularTenMinUsage;
}

- (void)setCellularTenMinusage:(unsigned long long)cellularTenMinusage {
    self.cellularTenMinUsage = cellularTenMinusage;
}

- (NSDictionary * _Nonnull)reportDictionary {
    return [NSDictionary dictionary];
}


- (NSDictionary * _Nullable)exceptionTrafficDictionary {
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    long long time = MilliSecond(self.timestamp);
    [dataDict setValue:@(time) forKey:@"timestamp"];
    [dataDict setValue:self.sessionID forKey:@"session_id"];
    [dataDict setValue:@(self.inAppTime) forKey:@"inapp_time"];
    [dataDict setValue:@"traffic" forKey:@"service"];
    [dataDict setValue:@"performance_monitor" forKey:@"log_type"];
    [dataDict setValue:@(self.localID) forKey:@"log_id"];
    [dataDict setValue:@(self.netQualityType) forKey:@"network_quality"];

    NSMutableDictionary *extraValues = [NSMutableDictionary dictionary];
    [extraValues setValue:@(self.tenMinUsage) forKey:@"usage_10_minutes"];
    [dataDict setValue:extraValues forKey:@"extra_values"];

    NSMutableDictionary *extraStatus = [NSMutableDictionary dictionary];
    [extraStatus setValue:self.scene forKey:@"scene"];
    [extraStatus setValue:self.frontType?:@"unknown" forKey:@"front"];
    [extraStatus setValue:self.netType?:@"unknown" forKey:@"net"];
    [dataDict setValue:extraStatus forKey:@"extra_status"];

    [dataDict setValue:@(self.isExceptionTraffic) forKey:@"exception"];
    if (self.exceptionTypes.count > 0) {
        [dataDict setValue:self.exceptionTypes forKey:@"exception_type"];
    }
    if (self.trafficDetail &&
        [self.trafficDetail isKindOfClass:[NSDictionary class]] &&
        self.trafficDetail.count > 0) {
        [dataDict setValue:self.trafficDetail forKey:@"detail"];
    }
    
    if (hermas_enabled()) {
        int64_t sequenceCode = self.enableUpload ? [[HMDHermasCounter shared] generateSequenceCode:@"HMDNetTrafficMonitorRecord"] : -1;
        [dataDict setValue:@(self.enableUpload) forKey:@"enable_upload"];
        [dataDict setValue:@(sequenceCode) forKey:@"sequence_code"];
        [dataDict setValue:@"HMDNetTrafficMonitorRecord" forKey:@"class_name"];
    }
    
    return dataDict;
}

- (BOOL)needAggregate {
    return NO;
}


@end
