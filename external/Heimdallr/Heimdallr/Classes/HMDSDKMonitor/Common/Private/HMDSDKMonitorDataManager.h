//
//  HMDSDKConfigInfo.h
//  AWECloudCommand
//
//  Created by zhangxiao on 2019/11/29.
//

#import <Foundation/Foundation.h>

@class HMDTTMonitor;
@class HMDRecordStore;
@class HMDTTMonitorUserInfo;
@class HMDHeimdallrConfig;

NS_ASSUME_NONNULL_BEGIN

@interface HMDSDKMonitorDataManager : NSObject

@property (nonatomic, strong) HMDTTMonitor *ttMonitor;
@property (nonatomic, strong) HMDTTMonitorUserInfo *ttMonitorUserInfo;
@property (nonatomic, copy) NSString *hostAid;
@property (nonatomic, copy) NSString *sdkAid;
@property (nonatomic, strong) HMDRecordStore *store;

- (instancetype)initSDKMonitorDataManagerWithSDKAid:(NSString *)sdkAid injectedInfo:(HMDTTMonitorUserInfo *)info;

@end

NS_ASSUME_NONNULL_END
