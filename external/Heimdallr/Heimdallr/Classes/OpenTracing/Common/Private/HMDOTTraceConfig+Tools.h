//
//  HMDOTTraceConfig+Tools.h
//  Heimdallr-8bda3036
//
//  Created by liuhan on 2022/6/9.
//

#import "HMDOTTraceConfig.h"

static const int kHMDOTMovingLineVersion = 1;

NS_ASSUME_NONNULL_BEGIN

@interface HMDOTTraceConfig (Tools)

+ (NSString *)generateRandom16LengthString;

- (NSString *)generateTraceID;

- (BOOL) isvalidHexString:(NSString *)hexStr;

@end

NS_ASSUME_NONNULL_END
