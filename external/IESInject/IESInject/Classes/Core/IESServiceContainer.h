//
//  IESServiceContainer.h
//  IESInject-Pods-Aweme
//
//  Created by bytedance on 2021/1/6.
//

#import <Foundation/Foundation.h>
#import "IESInjectScopeType.h"
#import "IESBlockDisposable.h"

NS_ASSUME_NONNULL_BEGIN


typedef id _Nonnull (^IESContainerProvider)(void);

@protocol IESServiceRegister <NSObject>

- (void)registerInstance:(id)instance forProtocol:(Protocol *)protocol;
- (void)registerInstance:(id)instance forProtocols:(NSArray<Protocol *> *)protocols;

- (void)registerInstance:(id)instance forClass:(Class)aClass;

- (void)registerClass:(Class)aClass forProtocol:(Protocol *)protocol scope:(IESInjectScopeType)scopeType;
- (void)registerClass:(Class)aClass forProtocols:(NSArray<Protocol *> *)protocols scope:(IESInjectScopeType)scopeType;

- (void)registerProvider:(IESContainerProvider)provider forClass:(Class)aClass scope:(IESInjectScopeType)scopeType;

- (void)registerProvider:(IESContainerProvider)provider forProtocol:(Protocol *)protocol scope:(IESInjectScopeType)scopeType;
- (void)registerProvider:(IESContainerProvider)provider forProtocols:(NSArray<Protocol *> *)protocols scope:(IESInjectScopeType)scopeType;

@end

@protocol IESServiceProvider <NSObject>

- (id)resolveObject:(id)classOrProtocol;
- (id)resolveCurrentContainerObject:(id)classOrProtocol;
- (id)resolveParentContainerObject:(id)classOrProtocol;

- (IESBlockDisposable * _Nullable)provideBlockNeedServiceResponse:(IESServiceResponeseBlock)block forProtocol:(Protocol *)protocol;

@end

NS_ASSUME_NONNULL_END
