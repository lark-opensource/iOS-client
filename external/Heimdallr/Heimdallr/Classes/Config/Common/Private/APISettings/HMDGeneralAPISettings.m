//
//  HMDGeneralAPISettings.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/5/23.
//

#import "HMDGeneralAPISettings.h"
#import "NSObject+HMDAttributes.h"

@implementation HMDGeneralAPISettings

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_CLASS(fetchAPISetting, fetch_setting, HMDConfigFetchSetting)
        HMD_ATTR_MAP_CLASS(performanceAPISetting, perf_event_upload, HMDPerformanceUploadSetting)
        HMD_ATTR_MAP_CLASS(doubleUploadSetting, network_monitor_double_upload, HMDDoubleUploadSettings)
        HMD_ATTR_MAP_CLASS(crashUploadSetting, crash_upload, HMDCommonAPISetting)
        HMD_ATTR_MAP_CLASS(exceptionUploadSetting, exception_upload, HMDCommonAPISetting)
        HMD_ATTR_MAP_CLASS(fileUploadSetting, file_upload, HMDCommonAPISetting)
        HMD_ATTR_MAP_CLASS(allAPISetting, all_api, HMDCommonAPISetting)
        HMD_ATTR_MAP_CLASS(cloudCommandSetting, cloud_control_setting, HMDCloudCommandSetting)
        HMD_ATTR_MAP_CLASS(hermasUploadSetting, hermas_setting, HMDHermasUploadSetting)
    };
}

@end
