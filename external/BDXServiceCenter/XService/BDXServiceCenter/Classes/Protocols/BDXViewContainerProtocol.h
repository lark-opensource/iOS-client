//
//  BDXViewContainerProtocol.h
//  BDXServiceCenter-Pods-Aweme
//
//  Created by bill on 2021/3/3.
//

#import <Foundation/Foundation.h>
#import "BDXServiceProtocol.h"
#import "BDXContainerProtocol.h"
#import "BDXKitProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class BDXContext;
@class BDXBridgeMethod;
@class BDXSchemaParam;

/// content mode of the bullet container view.
typedef NS_ENUM(NSInteger, BDXViewContentMode) {
    /// fixed size with the given frame.
    BDXViewContentModeFixedSize = 1,
    /// fixed width with the width of the given  frame, the height is determined
    /// by the content itself.
    BDXViewContentModeFixedWidth = 2,
    /// fixed height with the height of the given frame, the width is determined
    /// by the content itself.
    BDXViewContentModeFixedHeight = 3,
    /// both width and height are determined by the content itself.
    BDXViewContentModeFitSize = 4,
};

@protocol BDXViewContainerProtocol <BDXContainerProtocol>

/// 内部容器view的宽高布局模式，部分枚举值对某些容器类型设置无效
@property(nonatomic, assign) BDXViewContentMode bdxContentMode;
@property(nonatomic, readonly) UIView<BDXKitViewProtocol> *kitView;

/// load with url
/// @param url eg. sslocal://lynxview?url=xxxx
/// @param context if pass nil, context will be created internal
- (void)loadWithURL:(nullable NSString *)url context:(nullable BDXContext *)context;

/// using SchemaParam to load, SchemaParam can be created by BDXSchema Service
/// @param param SchemaParam
/// @param context can not be nil
- (void)loadWithParam:(BDXSchemaParam *)param context:(BDXContext *)context;

@end

@protocol BDXBridgeProviderProtocol <NSObject>

- (void)registerMethodsWithBridge:(id)bridge inContainer:(id<BDXViewContainerProtocol>)container;

@end

@protocol BDXViewContainerServiceProtocol <BDXServiceProtocol>

- (nullable UIView<BDXViewContainerProtocol> *)createViewContainerWithFrame:(CGRect)frame;

@end

@protocol BDXLoadingViewProtocol <NSObject>

@optional
- (void)startLoadingAnimation;
- (void)stopLoadingAnimation;

@end

@protocol BDXLoadErrorViewProtocol <NSObject>

@optional
- (void)container:(id<BDXViewContainerProtocol>)container didReceiveError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
