//
//  HMDCrashMetaData.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/20.
//

#import "HMDCrashMetaData.h"

@implementation HMDCrashMetaData

- (void)updateWithDictionary:(NSDictionary *)dict
{
    [super updateWithDictionary:dict];
    
    NSDictionary *metaDict = [dict hmd_dictForKey:@"meta"];
    self.arch = [metaDict hmd_stringForKey:@"arch"];
    self.processID = [metaDict hmd_unsignedIntegerForKey:@"process_id"];
    self.processName = [metaDict hmd_stringForKey:@"process_name"];
    self.osFullVersion = [metaDict hmd_stringForKey:@"os_full_version"];
    self.appVersion = [metaDict hmd_stringForKey:@"app_version"];
    self.bundleVersion = [metaDict hmd_stringForKey:@"bundle_version"];
    self.bundleID = [metaDict hmd_stringForKey:@"bundle_id"];
    self.UUID = [metaDict hmd_stringForKey:@"uuid"];
    self.osVersion = [metaDict hmd_stringForKey:@"os_version"];
    self.startTime = [metaDict hmd_doubleForKey:@"start_time"];
    self.deviceModel = [metaDict hmd_stringForKey:@"device_model"];
    self.osBuildVersion = [metaDict hmd_stringForKey:@"os_build_version"];
    self.physicalMemory = [metaDict hmd_unsignedLongLongForKey:@"physical_memory"];
    self.sdkVersion = [metaDict hmd_stringForKey:@"sdk_version"];
    self.commitID = [metaDict hmd_stringForKey:@"commit_id"];
    self.isAppExtension = [metaDict hmd_boolForKey:@"is_app_extension"];
    self.appExtensionType = [metaDict hmd_stringForKey:@"app_extension_type"];
    self.isMacARM = [metaDict hmd_boolForKey:@"is_mac_arm"];
    self.exceptionMainAddress = [metaDict hmd_unsignedLongForKey:@"exception_main_address"];
}

@end
