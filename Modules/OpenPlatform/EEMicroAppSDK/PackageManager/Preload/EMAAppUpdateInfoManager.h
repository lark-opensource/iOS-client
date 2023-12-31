//
//  EMAAppUpdateInfoManager.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/11/14.
//

#import <Foundation/Foundation.h>
#import "EMAAppUpdateInfo.h"
#import <OPFoundation/BDPUniqueID.h>

NS_ASSUME_NONNULL_BEGIN

@interface EMAAppUpdateInfoManager : NSObject

/// 返回 info
- (EMAAppUpdateInfo *)appUpdateInfoForUniqueID:(BDPUniqueID *)uniqueID;

/// 将 newUpdateInfo merge 到当前的 info 中
- (EMAAppUpdateInfo *)mergeNewUpdateInfo:(EMAAppUpdateInfo *)newUpdateInfo;

/// 有变更需要保存
- (void)markInfoChanged;
/// 保存变更
- (void)saveAll;

/// 所有应用总更新次数
- (NSUInteger)allAppUpdatedTimesWithAppInfo:(EMAAppUpdateInfo *)appInfo;

/// 应用列表（已按照优先级排序）
- (NSArray<EMAAppUpdateInfo *> *)updateInfos;

@end

NS_ASSUME_NONNULL_END
