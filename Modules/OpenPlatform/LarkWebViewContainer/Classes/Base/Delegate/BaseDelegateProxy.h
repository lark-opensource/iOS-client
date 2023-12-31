//
//  BaseDelegateProxy.h
//  LarkWebViewContainer
//
//  Created by houjihu on 2020/9/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 支持封装代理并支持扩展代理方法的底层实现类，支持Objc & Swift.
@interface BaseDelegateProxy : NSObject

/// 内部设置的delegate
@property (nonatomic, weak, nullable) id internDelegate;

/// 传入每次增删Delegate时执行的Block
@property (nonatomic, copy, nullable) os_block_t changeDelegateBlock;

/// 可选的 init 方法，允许传入每次增删Delegate时执行的Block
- (instancetype)initWithDelegate:(id)delegate changeDelegateBlock:(os_block_t)changeDelegateBlock;

@end

NS_ASSUME_NONNULL_END
