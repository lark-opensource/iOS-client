//
//  HMDGeneralAPISettings.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/5/23.
//

#import <Foundation/Foundation.h>
#import "HMDConfigFetchSetting.h"
#import "HMDPerformanceUploadSetting.h"
#import "HMDCloudCommandSetting.h"
#import "HMDDoubleUploadSettings.h"
#import "HMDHermasUploadSetting.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDGeneralAPISettings : NSObject

@property (nonatomic,strong) HMDConfigFetchSetting *fetchAPISetting;
@property (nonatomic,strong) HMDPerformanceUploadSetting *performanceAPISetting;
@property (nonatomic,strong) HMDCommonAPISetting *crashUploadSetting;
@property (nonatomic,strong) HMDCommonAPISetting *exceptionUploadSetting;
@property (nonatomic,strong) HMDCommonAPISetting *fileUploadSetting;
@property (nonatomic,strong) HMDCommonAPISetting *allAPISetting;
@property (nonatomic,strong) HMDCloudCommandSetting *cloudCommandSetting;
@property (nonatomic,strong) HMDDoubleUploadSettings *doubleUploadSetting;
@property (nonatomic,strong) HMDHermasUploadSetting *hermasUploadSetting;

@end

NS_ASSUME_NONNULL_END
