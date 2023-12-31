//
//  HMDStartRecord.m
//  Heimdallr
//
//  Created by fengyadong on 2018/6/14.
//

#import "HMDStartRecord.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

@implementation HMDStartRecord

+ (NSString *)tableName {
    return @"start";
}

+ (NSUInteger)cleanupWeight {
    return 20;
}

- (NSDictionary *)reportDictionary {
    NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
    
    long long time = MilliSecond(self.timestamp);
    [dataValue setValue:@(time) forKey:@"timestamp"];
    [dataValue setValue:self.sessionID forKey:@"session_id"];
    [dataValue setValue:@"start" forKey:@"service"];
    [dataValue setValue:@(self.localID) forKey:@"log_id"];
    [dataValue setValue:@(self.netQualityType) forKey:@"network_quality"];
    [dataValue setValue:@(self.prewarm) forKey:@"prewarm"];
    [dataValue setValue:@"performance_monitor" forKey:@"log_type"];
    
    NSMutableDictionary *extraValue = [NSMutableDictionary dictionary];
    NSString *type = self.timeType;
    if (type) {
        [extraValue setValue:@(self.timeInterval) forKey:type];
    }
    [dataValue setValue:extraValue forKey:@"extra_values"];
    [dataValue setValue:@(self.enableUpload) forKey:@"enable_upload"];
    if (hermas_enabled() && self.sequenceCode >= 0) {
        [dataValue setValue:@(self.sequenceCode) forKey:@"sequence_code"];
    }
    return dataValue;
}

@end
