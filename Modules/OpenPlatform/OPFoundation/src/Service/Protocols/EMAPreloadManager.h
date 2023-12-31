//
//  EMAPreloadManager.h
//  EEMicroAppSDK
//
//  Created by zhangxudong.999 on 2023/1/13.
//

#import <OPFoundation/BDPUniqueID.h>

typedef NS_ENUM(NSInteger, EMAPreloadType) {
    /// 持续定位预定位
    EMAPreloadTypeContinueLocation
};

@protocol EMAPreloadTask <NSObject>
@required
- (void)preloadWithUniqueID:(BDPUniqueID * _Nullable)uniqueID;
@end

@protocol EMAPreloadManager <EMAPreloadTask>
@required
- (id _Nullable)preloadTaskWithPreloadType:(EMAPreloadType)preloadType;
@end



