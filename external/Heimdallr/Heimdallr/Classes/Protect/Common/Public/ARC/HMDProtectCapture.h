//
//  HMDProtectCapture.h
//  HMDProtectCapture
//
//  Created by fengyadong on 2018/4/8.
//

#import <Foundation/Foundation.h>
#import "HMDThreadBacktrace.h"
#import "HMDProtectDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDProtectCapture : NSObject

@property(nonatomic, strong, nullable) NSString *exception;

@property(nonatomic, strong, nullable) NSString *reason;

// HMDProtectionType 不包含的保护类型该值为 HMDProtectionTypeNone
@property(nonatomic, assign) HMDProtectionType protectType;

@property(nonatomic, strong, nullable) NSString *protectTypeString;

@property(nonatomic, strong, nullable) NSArray<HMDThreadBacktrace*>* backtraces;

@property(nonatomic, strong, nullable) NSString *log;

@property(nonatomic, strong, nullable) id crashKey; // 崩溃场景key

@property(nonatomic, strong, nullable) NSMutableSet<id> *crashKeySet;

@property(nonatomic, strong, nullable) NSArray<NSString *> *crashKeyList;

@property(nonatomic, assign) BOOL filterWithTopStack; // 通过顶栈调用进行过滤

/** 添加上报到 custom 字段的数据 */
@property(nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> *customDictionary;

@property(nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> *customFilter;

+ (instancetype _Nullable)captureException:(NSString * _Nullable)exception reason:(NSString * _Nullable)reason;

+ (instancetype _Nullable)captureException:(NSString * _Nullable)exception
                                    reason:(NSString * _Nullable)reason
                                  crashKey:(NSString * _Nullable)crashKey;

+ (instancetype _Nullable)captureWithNSException:(__kindof NSException * _Nullable)exception;

+ (instancetype _Nullable)captureWithNSException:(__kindof NSException * _Nullable)exception
                                        crashKey:(NSString * _Nullable)crashKey;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
