//
//  HMDCloudCommandManager+config.m
//  Heimdallr
//
//  Created by liuhan on 2022/12/5.
//

#import "HMDCloudCommandManager+Private.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDPathComplianceTool.h"
#import "HMDCloudCommandConfig.h"
#import <AWECloudCommand/AWECloudCommandManager.h>

@interface HMDCloudCommandManager ()

@property (nonatomic, strong, readwrite) HMDCloudCommandConfig *cloudCommandConfig;
@property (atomic, assign, readwrite) BOOL isUpdatedConfig;
@property (nonatomic, strong) dispatch_semaphore_t configUpdateSemphore;

@end


@implementation HMDCloudCommandManager (Private)

- (void)updateConfig:(HMDCloudCommandConfig *)config {
    self.cloudCommandConfig = config;
    if (!self.isUpdatedConfig) {
        self.isUpdatedConfig = YES;
        dispatch_semaphore_signal(self.configUpdateSemphore);
    }
}

- (void)setDiskComplianceHandler {
    if ([[AWECloudCommandManager sharedInstance] respondsToSelector:@selector(setDiskPathsComplianceHandler:)]) {

        AWECloudCommandModel *(^handler)(AWECloudCommandModel *model);
        handler = ^(AWECloudCommandModel *model) {
            if (!self.isUpdatedConfig) {
                dispatch_semaphore_wait(self.configUpdateSemphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)));
            }
            NSString *path = [model.params hmd_stringForKey:@"path"];
            NSString *prefix = [model.params hmd_stringForKey:@"compliancePrefix"];
            BOOL complianceMatched = [model.params hmd_boolForKey:@"complianceMatched"];
            
            if (complianceMatched) {
                path = [HMDPathComplianceTool complianceReleativePath:path prefixPath:prefix];
            } else {
                path = [HMDPathComplianceTool compareAbsolutePath: path compliancePaths:self.cloudCommandConfig.complianceRelativePaths isMatch:&complianceMatched];
            }
            
            NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
            [params hmd_setObject:(path ?: @"") forKey:@"path"];
            [params hmd_setObject:@(complianceMatched) forKey:@"complianceMatched"];
            model.params = params;
            return model;
        };
        
        [[AWECloudCommandManager sharedInstance] performSelector:@selector(setDiskPathsComplianceHandler:) withObject: handler];
    }
}

@end
