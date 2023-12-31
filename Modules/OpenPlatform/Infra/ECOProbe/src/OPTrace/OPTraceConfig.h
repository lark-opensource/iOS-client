//
//  OPTraceConfig.h
//  LarkOPInterface
//
//  Created by changrong on 2020/9/14.
//

#import <Foundation/Foundation.h>

typedef NSString * _Nonnull(^GenerateNewTrace)(NSString * _Nonnull parentTraceId);
NS_ASSUME_NONNULL_BEGIN

@interface OPTraceConfig : NSObject

@property (nonatomic, copy, readonly) GenerateNewTrace generator;
@property (nonatomic, copy, readonly) NSString *prefix;

- (instancetype)initWithPrefix:(NSString *)prefix
                     generator:(GenerateNewTrace)generator;

/// 禁用默认初始化方法
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
