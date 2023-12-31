//
//  TSPKLogger.h
//  TSPrivacyKit-Pods-AwemeCore
//
//  Created by bytedance on 2022/1/11.
//

#import <Foundation/Foundation.h>

@interface TSPKLogger : NSObject

+ (void)logWithTag:(nonnull NSString *)tag message:(nonnull id)logObj;

+ (void)reportALogWithoutDelay;

+ (void)reportALog;

@end
