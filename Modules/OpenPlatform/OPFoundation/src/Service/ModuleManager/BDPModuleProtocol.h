//
//  BDPModuleProtocol.h
//  Timor
//
//  Created by houjihu on 2020/3/4.
//  Copyright © 2020 houjihu. All rights reserved.
//

#ifndef BDPModuleProtocol_h
#define BDPModuleProtocol_h

#import <Foundation/Foundation.h>
#import "BDPModuleManager.h"

NS_ASSUME_NONNULL_BEGIN

/// 模块协议
@protocol BDPModuleProtocol <NSObject>

/// 模块管理对象
@property (nonatomic, weak, nullable) BDPModuleManager *moduleManager;

@optional

/// 模块注册阶段：确定模块对外接口和模块实现绑定关系，此时模块已经准备好
+ (void)moduleDidLoadWithManager:(BDPModuleManager *)moduleManager;

@end

NS_ASSUME_NONNULL_END

#endif /* BDPModuleProtocol_h */
