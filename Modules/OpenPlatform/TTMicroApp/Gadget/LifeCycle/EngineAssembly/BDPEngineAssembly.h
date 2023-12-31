//
//  BDPEngineAssembly.h
//  Timor
//
//  Created by houjihu on 2020/3/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 引擎组装模块
/// 功能：组装不同形态应用的引擎所需要的模块
@interface BDPEngineAssembly : NSObject

/// 用于退出登陆时，清理跟所有应用类型文件目录相关的单例对象，便于再次登录时重新初始化
+ (void)clearAllSharedLocalFileManagers;

@end

NS_ASSUME_NONNULL_END
