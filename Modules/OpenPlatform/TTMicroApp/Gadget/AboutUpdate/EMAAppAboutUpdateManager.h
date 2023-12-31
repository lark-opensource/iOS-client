//
//  EMAAppAboutUpdateManager.h
//  EEMicroAppSDK
//
//  Created by tujinqiu on 2020/2/6.
//

#import <Foundation/Foundation.h>
#import "EMAAppAboutUpdateHandler.h"

@interface EMAAppAboutUpdateManager : NSObject

+ (instancetype)sharedManager;
// 拉取最新的Meta信息，如果有更新则下载包

- (void)fetchMetaAndDownloadWithUniqueID:(BDPUniqueID *)uniqueID
                        statusChanged:(EMAAppAboutUpdateCallback)statusChanged;
- (void)downloadWithUniqueID:(BDPUniqueID *)uniqueID
            statusChanged:(EMAAppAboutUpdateCallback)statusChanged;
- (BOOL)canRestartAppForUniqueID:(BDPUniqueID *)uniqueID;
- (void)restartAppForUniqueID:(BDPUniqueID *)uniqueID;
- (void)handleUpdateStatus:(EMAAppAboutUpdateStatus)status uniqueID:(BDPUniqueID *)uniqueID;

- (NSString *)getAppVersionWithUniqueID:(BDPUniqueID *)uniqueID;
@end

