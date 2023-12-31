//
//  HMDCDConfig.m
//  Heimdallr
//
//  Created by maniackk on 2020/11/4.
//

#import "HMDCDConfig.h"
#import "HMDCDGenerator.h"
#import "HMDCDConfig+Private.h"
#import "NSObject+HMDAttributes.h"
#import "hmd_section_data_utility.h"

NSString *const kHMDModuleCoreDump = @"core_dump";

HMD_MODULE_CONFIG(HMDCDConfig)

@implementation HMDCDConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        
        HMD_ATTR_MAP_DEFAULT(minFreeDiskUsageMB, min_free_disk_usage_mb,
                            @(HMD_CD_DEFAULT_minFreeDiskUsageMB),
                            @(HMD_CD_DEFAULT_minFreeDiskUsageMB))
        
        
        HMD_ATTR_MAP_DEFAULT(maxCDFileSizeMB, max_cdfile_size_mb,
                            @(HMD_CD_DEFAULT_maxCDFileSizeMB),
                            @(HMD_CD_DEFAULT_maxCDFileSizeMB))
        
        HMD_ATTR_MAP_DEFAULT(maxCDZipFileSizeMB, max_cdzipfile_size_mb, 
                            @(HMD_CD_DEFAULT_maxCDZipFileSizeMB),
                            @(HMD_CD_DEFAULT_maxCDZipFileSizeMB))
        
        
        HMD_ATTR_MAP_DEFAULT(dumpNSException, dump_nsexception, 
                            @(HMD_CD_DEFAULT_dumpNSException),
                            @(HMD_CD_DEFAULT_dumpNSException))
        
        HMD_ATTR_MAP_DEFAULT(dumpCPPException, dump_cppexception, 
                            @(HMD_CD_DEFAULT_dumpCPPException),
                            @(HMD_CD_DEFAULT_dumpCPPException))
    };
}

+ (NSString *)configKey {
    return kHMDModuleCoreDump;
}

- (id<HeimdallrModule>)getModule {
    return [HMDCDGenerator sharedGenerator];
}
@end
