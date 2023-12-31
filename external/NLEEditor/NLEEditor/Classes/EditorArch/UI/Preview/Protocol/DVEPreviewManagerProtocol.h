//
//  DVEPreviewManagerProtocol.h
//  Pods
//
//  Created by pengzhenhuan on 2022/1/4.
//

#import <Foundation/Foundation.h>
#import "DVECoreProtocol.h"
#import "DVEPreviewPluginProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DVEPreviewManagerProtocol <DVECoreProtocol>

@property (nonatomic, assign) DVEPreviewEditType editType;

///获取preview容器view
- (UIView *)previewContainerView;

///更新preview在新的frame的显示区域size
- (void)updatePreviewSizeAspectInFrame:(CGRect)frame;

///展示插件
- (void)showPlugin:(id<DVEPreviewPluginProtocol>)plugin;

///移除插件
- (void)dismissPlugin:(id<DVEPreviewPluginProtocol>)plugin;

///根据点获取在该点上的所有plugin
- (NSMapTable<id<DVEPreviewPluginProtocol>, NSNumber *> *)pluginMapLayersLocateContainPoint:(CGPoint)point;

///在某些场景下需要disble掉某些可以响应编辑模式types的插件
- (void)disablePluginWithTypes:(NSArray<NSNumber *> *)types;

///将plugin层级提到最前
- (void)bringPluginToFront:(id<DVEPreviewPluginProtocol>)plugin;

///更新当前挂载到preview的plugin，通常在改变了preview的size之后调用
- (void)updatePreviewPluginIfNeed;

@end


NS_ASSUME_NONNULL_END
