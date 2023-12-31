//
//  IESStaticContainer.h
//  IESInject
//
//  Created by bytedance on 2020/4/7.
//

#import "IESContainer.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESServiceScopeBase : NSObject

@property (nonatomic, copy, readonly) IESContainerProvider provider;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)init:(IESContainerProvider)provider NS_DESIGNATED_INITIALIZER;

@end

@protocol IESServiceScopeTypeConvertable <NSObject>

- (IESInjectScopeType)scope;

@end

NS_SWIFT_NAME(ServiceScopeNormal)
@interface IESServiceScopeNormal : IESServiceScopeBase <IESServiceScopeTypeConvertable>

@end

NS_SWIFT_NAME(ServiceScopeWeak)
@interface IESServiceScopeWeak : IESServiceScopeBase <IESServiceScopeTypeConvertable>

@end

NS_SWIFT_NAME(ServiceScopeSingleton)
@interface IESServiceScopeSingleton : IESServiceScopeBase <IESServiceScopeTypeConvertable>

@end

@interface IESStaticContainer : IESContainer

@end

NS_ASSUME_NONNULL_END
