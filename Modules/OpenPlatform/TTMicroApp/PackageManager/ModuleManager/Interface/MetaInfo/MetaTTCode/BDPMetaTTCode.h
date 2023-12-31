//
//  BDPMetaTTCode.h
//  Timor
//
//  Created by houjihu on 2020/6/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// meta加密code
@interface BDPMetaTTCode : NSObject

/// 用于加密的key a
@property (nonatomic, copy) NSString *aesKeyA;
/// 用于加密的key b
@property (nonatomic, copy) NSString *aesKeyB;
/// 加密code
@property (nonatomic, copy) NSString *ttcode;

//应用内置包默认的 TTCode 配置值，其他场景请勿使用
+(BDPMetaTTCode *)buildInAppCode;
@end

NS_ASSUME_NONNULL_END
