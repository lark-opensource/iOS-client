//
//  IESBlockDisposable.h
//  IESInject-Pods-Aweme
//
//  Created by bytedance on 2021/7/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class IESContainer;
typedef void (^IESServiceResponeseBlock)(id _Nonnull serviceImpl);

@interface IESBlockDisposable : NSObject

@property (atomic, assign, getter = isDisposed, readonly) BOOL disposed;
@property (nonatomic, copy, readonly) IESServiceResponeseBlock block;
@property (nonatomic, copy, readonly) NSString *relatedServiceKey;

- (instancetype)initWithBlock:(IESServiceResponeseBlock)block serviceKey:(NSString *)relatedServiceKey serviceContainer:(IESContainer *)container;

/// remove block registered in serviceContainer
/// only run before service registered.
/// After service registered, related block will be removed automatically, call dispose method will do nothing.
- (void)dispose;

@end

NS_ASSUME_NONNULL_END
