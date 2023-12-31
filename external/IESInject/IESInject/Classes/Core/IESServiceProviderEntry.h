//
//  IESServiceProviderEntry.h
//  IESInject
//
//  Created by bytedance on 2020/2/10.
//

#import "IESServiceEntry.h"
#import "IESContainer.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESServiceProviderEntry : IESServiceEntry

- (instancetype)initWithProvider:(IESContainerProvider)provider scopeType:(IESInjectScopeType)scopeType;

- (instancetype)initWithClass:(Class)aClass scopeType:(IESInjectScopeType)scopeType;

@end

NS_ASSUME_NONNULL_END
