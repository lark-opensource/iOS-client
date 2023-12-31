//
//  BDPCommunicationModule.h
//  Timor
//
//  Created by houjihu on 2020/3/30.
//

#import "BDPCommunicationModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/// 通信模块
/// 功能：建立渲染层、逻辑层以及native之间的通信
@interface BDPCommunicationModule : NSObject <BDPCommunicationModuleProtocol>

/// 模块管理对象
@property (nonatomic, weak) BDPModuleManager *moduleManager;

@end

NS_ASSUME_NONNULL_END
