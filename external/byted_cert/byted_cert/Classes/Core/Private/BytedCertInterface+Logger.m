//
//  BytedCertInterface+Logger.m
//  byted_cert
//
//  Created by liuminghui.2022 on 2023/3/21.
//

#import "BytedCertInterface+Logger.h"
#import "BDCTLog.h"


@implementation BytedCertInterface (Logger)

+ (void)logWithInfo:(NSString *__nonnull)info params:(NSDictionary<NSString *, NSString *> *_Nullable)params {
    BytedCertInterface *bytedIf = [BytedCertInterface sharedInstance];
    if ([bytedIf.bytedCertLoggerDelegate respondsToSelector:@selector(info:params:)]) {
        [bytedIf.bytedCertLoggerDelegate info:info params:params];
    } else {
        BDCTLogInfo(info);
    }
}

+ (void)logWithErrorInfo:(NSString *)errMsg params:(NSDictionary<NSString *, NSString *> *_Nullable)params error:(NSError *_Nullable)error {
    BytedCertInterface *bytedIf = [BytedCertInterface sharedInstance];
    if ([bytedIf.bytedCertLoggerDelegate respondsToSelector:@selector(error:params:error:)]) {
        [bytedIf.bytedCertLoggerDelegate error:errMsg params:params error:error];
    } else {
        BDCTLogInfo(errMsg);
    }
}

@end
