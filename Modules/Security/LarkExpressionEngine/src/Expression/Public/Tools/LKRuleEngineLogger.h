//
//  LKRuleEngineLogger.h
//  LarkExpressionEngine
//
//  Created by 汤泽川 on 2022/11/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define RLLog(frmt, level, ...) [[LKRuleEngineLogger sharedInstance] logWithLevel:level message:[NSString stringWithFormat:frmt, ##__VA_ARGS__] file:[NSString stringWithFormat:@"%s", __FILE__] line:__LINE__ function:[NSString stringWithFormat:@"%s" ,__PRETTY_FUNCTION__]]

#define RLLogE(frmt, ...) RLLog(frmt, LKRuleEngineLogLevelError, ##__VA_ARGS__)
#define RLLogW(frmt, ...) RLLog(frmt, LKRuleEngineLogLevelWarn, ##__VA_ARGS__)
#define RLLogI(frmt, ...) RLLog(frmt, LKRuleEngineLogLevelInfo, ##__VA_ARGS__)
#define RLLogD(frmt, ...) RLLog(frmt, LKRuleEngineLogLevelDebug, ##__VA_ARGS__)

typedef NS_ENUM(NSUInteger, LKRuleEngineLogLevel) {
    LKRuleEngineLogLevelInfo = 0,
    LKRuleEngineLogLevelDebug,
    LKRuleEngineLogLevelWarn,
    LKRuleEngineLogLevelError
};

@protocol LKRuleEngineLogger <NSObject>

- (void)logWithLevel:(LKRuleEngineLogLevel)level message:(NSString *)message file:(NSString *)file line:(NSInteger)line function:(NSString *)function;

@end

@interface LKRuleEngineLogger : NSObject<LKRuleEngineLogger>

+ (instancetype)sharedInstance;
/// strong reference for logger
+ (void)registerLogger:(id<LKRuleEngineLogger>)logger;

@end

NS_ASSUME_NONNULL_END
