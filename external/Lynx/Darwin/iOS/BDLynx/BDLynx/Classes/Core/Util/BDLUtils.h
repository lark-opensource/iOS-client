//
//  BDLUtils.h
//  BDLynx
//
//  Created by zys on 2020/2/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define BDLINFO(format, ...) \
  ([BDLUtils info:[NSString stringWithFormat:format, ##__VA_ARGS__, nil]])
#define BDLERROR(format, ...) \
  ([BDLUtils error:[NSString stringWithFormat:format, ##__VA_ARGS__, nil]])
#define WEAKSELF __weak __typeof(self) weakSelf = self;
#define STRONGSELF __strong __typeof(weakSelf) strongSelf = weakSelf;
@interface BDLUtils : NSObject

+ (void)info:(NSString *)info;
+ (void)warn:(NSString *)warn;
+ (void)error:(NSString *)error;
+ (void)fatal:(NSString *)fatal;
+ (void)reportLog:(NSString *)message;

+ (void)logToSystem:(NSNumber *)isOpen;

/**
 *  Sladar 监控
 *  监控某个service的值，并上报
 *  @param serviceName 埋点
 *  @param value 是一个float类型的，不可枚举
 *  @param extraValue 额外信息，方便追查问题使用
 */
+ (void)trackService:(NSString *)serviceName value:(float)value extra:(NSDictionary *)extraValue;

+ (void)trackData:(NSDictionary *)data logTypeStr:(NSString *)type;

/**
 * 埋点上报
 * @param eventName 埋点名
 * @param params 自定义参数
 */
+ (void)event:(NSString *)eventName params:(NSDictionary *)params;

+ (void)openSchema:(NSString *)schema;

+ (NSString *)bdl_md5StringOfString:(NSString *)source;

@end

/// Returns If Array is Empty or Invalid
FOUNDATION_EXTERN BOOL BDLIsEmptyArray(NSArray *_Nullable array);

/// Returns If String is Empty or Invalid
FOUNDATION_EXTERN BOOL BDLIsEmptyString(NSString *_Nullable string);

/// Returns If Dictionary is Empty or Invalid
FOUNDATION_EXTERN BOOL BDLIsEmptyDictionary(NSDictionary *_Nullable dict);

/// Returns NSArray Absolutely (Include Nil or Invalid Class)
FOUNDATION_EXTERN NSArray *_Nonnull BDLSafeArray(NSArray *_Nullable array);

/// Returns NSString Absolutely (Include Nil or Invalid Class)
FOUNDATION_EXTERN NSString *_Nonnull BDLSafeString(NSString *_Nullable string);

/// Returns NSDictionary Absolutely (Include Nil or Invalid Class)
FOUNDATION_EXTERN NSDictionary *_Nonnull BDLSafeDictionary(NSDictionary *_Nullable dict);

NS_ASSUME_NONNULL_END
