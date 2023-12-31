//
//  DVEPreviewPluginProtocol.h
//  Pods
//
//  Created by pengzhenhuan on 2022/1/4.
//

#import <Foundation/Foundation.h>
#import "DVEPreviewGestureListenerProtocol.h"
#import <DVEFoundationKit/DVECommonDefine.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DVEPreviewPluginProtocol <NSObject>

- (void)pluginWillShowOnView:(UIView *)parentView;

- (void)pluginWillDismiss;

- (void)pluginWillHide:(BOOL)hide;

- (void)pluginUpdateIfNeedWithPreviewSize:(CGSize)size;

///获取plugin的view对象
- (nullable UIView *)pluginView;

@optional

///plugin可以响应的编辑模式
- (NSArray<NSNumber *> *)responseEditTypeForPlugin;

- (BOOL)isPluginRespondsWithPoint:(CGPoint)point;

///获取plugin手势监听对象
- (id<DVEPreviewGestureListenerProtocol>)gestureListener;

@end

NS_ASSUME_NONNULL_END
