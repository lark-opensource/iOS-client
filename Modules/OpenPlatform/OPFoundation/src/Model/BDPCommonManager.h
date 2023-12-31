//
//  BDPCommonManager.h
//  Timor
//
//  Created by 王浩宇 on 2019/5/23.
//

#import <Foundation/Foundation.h>
#import "BDPCommon.h"
#import "BDPUniqueID.h"

// 方便的宏
#define BDPCommonFromUniqueID(uniqueID) [BDPCommonManager.sharedManager getCommonWithUniqueID:uniqueID]
#define BDPCurrentCommon BDPCommonFromUniqueID(self.uniqueID)

/// 小程序Common对象管理器，使用BDPUniqueID为key进行隔离
@interface BDPCommonManager : NSObject

+ (instancetype)sharedManager;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

// 外部调用方避免多线程问题
/// 添加common对象
/// @param common 当前小程序实例中与宿主无关的相关内容
/// @param uniqueID 通用应用的唯一复合ID
- (void)addCommon:(BDPCommon *)common uniqueID:(BDPUniqueID *)uniqueID;

/// 移除common对象
/// @param uniqueID 当前小程序实例中与宿主无关的相关内容
- (void)removeCommonWithUniqueID:(BDPUniqueID *)uniqueID;

/// 通过uniqueID获取BDPCommon
/// @param uniqueID 通用应用的唯一复合ID
- (BDPCommon *)getCommonWithUniqueID:(BDPUniqueID *)uniqueID;

@end
