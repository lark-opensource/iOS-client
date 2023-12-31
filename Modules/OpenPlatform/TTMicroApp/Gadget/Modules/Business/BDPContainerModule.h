//
//  BDPContainerModule.h
//  Timor
//
//  Created by houjihu on 2020/3/30.
//

#import "BDPContainerModuleProtocol.h"
#import <OPFoundation/BDPModuleEngineType.h>

NS_ASSUME_NONNULL_BEGIN



/// 容器模块
/// 功能：应用vc、页面vc、导航栏vc、TabBar vc、关于vc相关功能
@interface BDPContainerModule : NSObject <BDPContainerModuleProtocol>   //  Tips: BDPContainerModuleProtocol声明的方法不要在这个.h再声明一次了

/// 模块管理对象
@property (nonatomic, weak) BDPModuleManager *moduleManager;

@end

NS_ASSUME_NONNULL_END
