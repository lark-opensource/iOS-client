//
//  NSData+DataDecorator.h
//  BDDataDecorator
//
//  Created by bob on 2019/11/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (DataDecorator)

/// 设置接口仅提供给AppLog调用，后端统一控制，其他业务请勿调用
@property (nonatomic, assign, class) BOOL bd_dataUseRandom;

/// applog的通用加密方法
- (nullable NSData *)bd_dataByDecorated;

@end

NS_ASSUME_NONNULL_END
