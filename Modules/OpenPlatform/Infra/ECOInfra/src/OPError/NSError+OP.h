//
//  NSError+OP.h
//  LarkOPInterface
//
//  Created by yinyuan on 2020/7/13.
//

#import <Foundation/Foundation.h>

@class OPError;

NS_ASSUME_NONNULL_BEGIN

@interface NSError (OP)

/// 读取绑定的 OPError，如果没有则返回空
@property (nonatomic, strong, readonly, nullable) OPError *opError NS_SWIFT_UNAVAILABLE("Please use `as? OPError` in swift");

@end

NS_ASSUME_NONNULL_END
