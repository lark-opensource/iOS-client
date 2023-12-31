//
//  BDPLogicLayerModule.h
//  Timor
//
//  Created by houjihu on 2020/3/30.
//

#import "BDPLogicLayerModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/// 应用生命周期模块
/// 功能：发送应用相关生命周期事件，保存应用前后台等状态
@interface BDPLogicLayerModule : NSObject <BDPLogicLayerModuleProtocol>

/// 模块管理对象
@property (nonatomic, weak) BDPModuleManager *moduleManager;

@end

NS_ASSUME_NONNULL_END
