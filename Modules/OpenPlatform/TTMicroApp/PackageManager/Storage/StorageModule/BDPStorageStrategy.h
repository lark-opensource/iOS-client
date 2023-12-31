//
//  BDPStorageStrategy.h
//  Timor
//
//  Created by houjihu on 2020/5/14.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPModuleEngineType.h>

NS_ASSUME_NONNULL_BEGIN

/// 存储模块策略类：针对不同应用形态，设置不同的处理策略
@interface BDPStorageStrategy : NSObject

/// 同一用户维度下，返回各应用形态的文件系统根目录名称
/// @param type 应用形态类型
+ (NSString *)rootDirectoryPathForType:(BDPType)type;

@end

NS_ASSUME_NONNULL_END
