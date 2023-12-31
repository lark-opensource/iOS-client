//
//  NSData+DataDecorator.h
//  BDDataDecorator
//
//  Created by bob on 2019/11/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (DataDecoratorTob)

/// applog 私有化通用加密方法
- (nullable NSData *)bd_dataByPrivateDecorated;

@end

NS_ASSUME_NONNULL_END
