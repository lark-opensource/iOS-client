//
//  BytedCertInterface+Logger.h
//  byted_cert
//
//  Created by liuminghui.2022 on 2023/3/21.
//

#import "BytedCertInterface.h"

NS_ASSUME_NONNULL_BEGIN


@interface BytedCertInterface (Logger)

+ (void)logWithInfo:(NSString *__nonnull)info params:(NSDictionary<NSString *, NSString *> *_Nullable)params;

+ (void)logWithErrorInfo:(NSString *__nonnull)errMsg params:(NSDictionary<NSString *, NSString *> *_Nullable)params error:(NSError *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
