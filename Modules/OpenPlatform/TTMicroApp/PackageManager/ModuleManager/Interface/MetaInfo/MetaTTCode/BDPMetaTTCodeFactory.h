//
//  BDPMetaTTCodeFactory.h
//  Timor
//
//  Created by houjihu on 2020/6/12.
//

#import <Foundation/Foundation.h>
#import "BDPMetaTTCode.h"

NS_ASSUME_NONNULL_BEGIN

/// 生成用于请求meta的ttcode的工厂类
@interface BDPMetaTTCodeFactory : NSObject

/// 生成的ttcode
@property (nonatomic, strong, class, readonly) BDPMetaTTCode *ttcode;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// 预先生成一个ttcode
+ (void)generateTTCodeIfNeeded;

/// 获取预先生成的ttcode
+ (BDPMetaTTCode *)fetchPreGenerateTTCode;

@end

NS_ASSUME_NONNULL_END
