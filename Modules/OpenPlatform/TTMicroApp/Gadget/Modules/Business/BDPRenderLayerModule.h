//
//  BDPRenderLayerModule.h
//  Timor
//
//  Created by houjihu on 2020/3/30.
//

#import "BDPRenderLayerModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/// 渲染层模块
/// 功能：加载渲染层、注册bridge
@interface BDPRenderLayerModule : NSObject <BDPRenderLayerModuleProtocol>

/// 模块管理对象
@property (nonatomic, weak) BDPModuleManager *moduleManager;

@end

NS_ASSUME_NONNULL_END
