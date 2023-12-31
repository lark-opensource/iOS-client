//
//  Heimdallr+SafeMode.m
//  Heimdallr
//
//  Created by zhouyang11 on 2023/10/11.
//

#import "Heimdallr+SafeMode.h"
#import "Heimdallr+Private.h"
#import "HeimdallrUtilities.h"
#import "HMDFileTool.h"
#import "HMDServiceContext.h"
#import "HMDDynamicCall.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDConfigManager.h"
#import "NSDictionary+HMDJSON.h"
#import "HMDMacro.h"
#import <sys/mman.h>
#import "HMDALogProtocol.h"
#import "HMDUserDefaults.h"

static const int HMDSafeModeMildTolerateNumber = 3;
static const int HMDSafeModeCriticalTolerateNumber = 5;
static NSString* const HMDSafeModeTmpFileName = @"hmd_safe_mode_tmp_file";
static NSString* const HMDCrashModuleDirectoryName = @"CrashCapture";
static NSString* const HMDCrashConfigClassName = @"HMDCrashConfig";
static NSString* const HMDSettingsCrashConfigPath = @"exception_modules/crash";
static NSString* const HMDSettingsSafeModeConfigPath = @"general/slardar_api_settings/safe_mode_setting";

typedef struct {
    int crashCount;
    bool userTerminate;
    bool isBackground;
}HMDSafeModeStruct;

static HMDSafeModeStruct *hmdSafeModePtr = NULL;
static char* hmdSafeModeTMPFilePath = NULL;
static bool hmdSafeModeAvailable = false;

@implementation Heimdallr (SafeMode)

- (void)safeModeCheck {
    NSString *safeModeDirectoryPath = [HeimdallrUtilities heimdallrRootPath];
    NSString *safeModeTmpFilePath = [safeModeDirectoryPath stringByAppendingPathComponent:HMDSafeModeTmpFileName];
    
    NSDictionary *safeModeConfig = [[self cachedConfigData]valueForKeyPath:@"general.slardar_api_settings.safe_mode_setting"];
    if (![safeModeConfig hmd_boolForKey:@"enable_open"]) {
        remove(safeModeTmpFilePath.UTF8String);
        HMDLog(@"safe mode disable");
        return;
    }
    
    if (self.safeModeType != HMDSafeModeTypeDefault) {
        return;
    }
    hmdCheckAndCreateDirectory(safeModeDirectoryPath);
    hmdSafeModeTMPFilePath = strdup(safeModeTmpFilePath.UTF8String);
    
    bool tmpFileExist = true;
    int fd = open(safeModeTmpFilePath.UTF8String, O_RDWR);
    if (fd == -1) {
        fd = open(safeModeTmpFilePath.UTF8String, O_RDWR|O_CREAT, S_IRUSR|S_IWUSR);
        if (fd != -1) {
            if(ftruncate(fd, sizeof(HMDSafeModeStruct)) == -1) {
                remove(hmdSafeModeTMPFilePath);
                free(hmdSafeModeTMPFilePath);
                return;
            }
        }
        tmpFileExist = false;
    }
    hmdSafeModePtr = (HMDSafeModeStruct*)mmap(NULL, sizeof(HMDSafeModeStruct), PROT_READ|PROT_WRITE, MAP_FILE|MAP_SHARED, fd, 0);
    close(fd);
    if (hmdSafeModePtr != (void*)-1) {
        mlock(hmdSafeModePtr, sizeof(HMDSafeModeStruct));
        hmdSafeModeAvailable = true;
    }else {
        return;
    }
    BOOL lastApplicationIsBackground = hmdSafeModePtr->isBackground;
    BOOL lastApplicationUserTerminate = hmdSafeModePtr->userTerminate;
    hmdSafeModePtr->isBackground = [HMDBackgroundMonitor sharedInstance].isBackground;
    [[HMDBackgroundMonitor sharedInstance] addStatusChangeDelegate:self];
    
    int64_t time = [safeModeConfig hmd_intForKey:@"timeout_duration"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), hmd_get_heimdallr_queue(), ^{
        [self safeModeCleanDueToTimeout:YES];
    });
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hmdSafeModeAppWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
    
    if (tmpFileExist == false) {
        self.safeModeType = HMDSafeModeTypeNormal;
        HMDLog(@"safe mode normal");
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"safe mode check normal");
        return;
    }
    if (lastApplicationUserTerminate || lastApplicationIsBackground) {
        memset(hmdSafeModePtr, 0, sizeof(HMDSafeModeStruct));
        self.safeModeType = HMDSafeModeTypeNormal;
        HMDLog(@"safe mode normal with %@", lastApplicationUserTerminate?@"user terminate":@"background");
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"safe mode check normal with %@", lastApplicationUserTerminate?@"user terminate":@"background");
        return;
    }
    hmdSafeModePtr->crashCount = hmdSafeModePtr->crashCount+1;
    HMDLog(@"safe mode continuous crash %d times", hmdSafeModePtr->crashCount);
    
    [self hmdSafeModeContinuousCrashWithCount:hmdSafeModePtr->crashCount];
}

- (void)hmdSafeModeContinuousCrashWithCount:(int)crashCount {
    NSString *safeModeTypeDesc = nil;
    HMDSafeModeType safeModeType = HMDSafeModeTypeBelowMild;
    if (crashCount == HMDSafeModeMildTolerateNumber) {
        safeModeType = HMDSafeModeTypeMild;
        safeModeTypeDesc = @"mild";
    }else if (crashCount > HMDSafeModeMildTolerateNumber && crashCount < HMDSafeModeCriticalTolerateNumber) {
        safeModeType = HMDSafeModeTypeBetweenMildAndCritical;
        safeModeTypeDesc = @"between mild and critical";
    }else if (crashCount == HMDSafeModeCriticalTolerateNumber) {
        safeModeType = HMDSafeModeTypeCritical;
        safeModeTypeDesc = @"critical";
    }else if (crashCount > HMDSafeModeCriticalTolerateNumber) {
        safeModeType = HMDSafeModeTypeBeyoundCritical;
        safeModeTypeDesc = @"beyond critical";
    }
    
    self.safeModeType = safeModeType;
    if (safeModeTypeDesc != nil) {
        id<HMDTTMonitorServiceProtocol> ttMonitor = hmd_get_heimdallr_ttmonitor();
        [ttMonitor hmdUploadImmediatelyTrackService:@"hmd_sdk_safe_mode_invoke" metric:nil category:@{@"safe_mode_type":safeModeTypeDesc} extra:nil];
        NSDictionary *crashSyncConfig = [[Heimdallr syncStartModuleSettings] hmd_dictForKey:HMDCrashConfigClassName];
        if (crashSyncConfig) {
            [[HMDUserDefaults standardUserDefaults] setObject:@{HMDCrashConfigClassName:crashSyncConfig} forKey:kHMDSyncModulesKey];
        }
    }
    [HMDConfigManager sharedInstance].shouldForceRefreshConfigOnce = YES;
    if (safeModeType == HMDSafeModeTypeCritical) {
        [self hmdSafeModeCriticalTypeInvoke];
    }else if (safeModeType == HMDSafeModeTypeMild){
        [self hmdSafeModeMildTypeInvoke];
    }
    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"hmd safe mode identify continous crash %d times", crashCount);
    HMDLog(@"hmd safe mode identify continous crash %d times, status: %@", crashCount, safeModeTypeDesc);
}

- (NSDictionary*)cachedConfigData {
    NSString *hostConfigPath = [[HMDConfigManager sharedInstance]configPathWithAppID:self.userInfo.appID];
    NSData *data = [NSData dataWithContentsOfFile:hostConfigPath];
    if (!data) {
        return nil;
    }
    NSDictionary *origDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return origDict;
}

- (void)rewriteHostConfigFileWithModulesReserve:(NSArray<NSString*>*)moduleNames {
    NSString *hostConfigPath = [[HMDConfigManager sharedInstance]configPathWithAppID:self.userInfo.appID];
    NSDictionary *origDict = [self cachedConfigData];
    if (origDict.count == 0) {
        return;
    }
    NSMutableDictionary *newDict = [NSMutableDictionary dictionary];
    for (NSString* moduleName in moduleNames) {
        NSArray<NSString*>* paths = [moduleName componentsSeparatedByString:@"/"];
        NSMutableDictionary *tmp = nil;
        NSDictionary *origTmp = origDict;
        NSMutableDictionary *newTmp = newDict;
        for (int i = 0; i < paths.count; i++) {
            NSString *path = paths[i];
            if (i == paths.count-1) {
                [newTmp hmd_setObject:[origTmp hmd_dictForKey:path] forKey:path];
            }else {
                tmp = [newTmp hmd_objectForKey:path class:NSMutableDictionary.class];
                if (!tmp) {
                    tmp = [NSMutableDictionary dictionary];
                    [newTmp hmd_setObject:tmp forKey:path];
                }
                newTmp = tmp;
                origTmp = [origTmp hmd_dictForKey:path].mutableCopy;
            }
        }
    }
    [[newDict hmd_jsonData] writeToFile:hostConfigPath atomically:YES];
}

- (void)hmdSafeModeMildTypeInvoke {
    NSString *hostConfigPath = [[HMDConfigManager sharedInstance]configPathWithAppID:self.userInfo.appID];
    NSString *hostConfigFileName = hostConfigPath.lastPathComponent;
    
    [self rewriteHostConfigFileWithModulesReserve:@[HMDSettingsCrashConfigPath, HMDSettingsSafeModeConfigPath]];
    HMDLog(@"rewrite config due to safe model mild");
    NSString* heimdallrRootPath = [HeimdallrUtilities heimdallrRootPath];
    NSArray<NSString*>* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:heimdallrRootPath error:nil];
    for (NSString* item in contents) {
        if ([item hasSuffix:HMDConfigFilePathSuffix] && ![item isEqualToString:hostConfigFileName]) {
            CLANG_DIAGNOSTIC_PUSH
            CLANG_DIAGNOSTIC_IGNORE_UNUSED_VARIABLE
            int res = remove([heimdallrRootPath stringByAppendingPathComponent:item].UTF8String);
            CLANG_DIAGNOSTIC_POP
            HMDLog(@"remove %@ due to safe mode mild invoke, res = %@", item, res==0?@"success":@"fail");
        }
    }
}

- (void)hmdSafeModeCriticalTypeInvoke {
    [self rewriteHostConfigFileWithModulesReserve:@[HMDSettingsCrashConfigPath,HMDSettingsSafeModeConfigPath]];
    HMDLog(@"rewrite config due to safe model critical");
    NSString *hostConfigPath = [[HMDConfigManager sharedInstance]configPathWithAppID:self.userInfo.appID];
    NSString *hostConfigFileName = hostConfigPath.lastPathComponent;
    NSString* heimdallrRootPath = [HeimdallrUtilities heimdallrRootPath];
    NSArray<NSString*>* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:heimdallrRootPath error:nil];
    for (NSString* item in contents) {
        if ([item isEqualToString:HMDCrashModuleDirectoryName] ||
            [item isEqualToString:hostConfigFileName] ||
            [item isEqualToString:HMDSafeModeTmpFileName] ||
            [item isEqualToString:HMDSafeModeRemainDirectory]) {
            continue;
        }
        [[NSFileManager defaultManager] removeItemAtPath:[heimdallrRootPath stringByAppendingPathComponent:item] error:nil];
        HMDLog(@"remove %@ due to safe mode critical invoke", item);
    }
}

- (void)hmdSafeModeAppWillTerminate {
    dispatch_on_heimdallr_queue(true, ^{
        if (hmdSafeModePtr != NULL) {
            hmdSafeModePtr->userTerminate = true;
        }
    });
}

- (void)safeModeCleanDueToTimeout:(BOOL)timeout {
    dispatch_on_heimdallr_queue(true, ^{
        if (hmdSafeModeAvailable) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
            [[HMDBackgroundMonitor sharedInstance] removeStatusChangeDelegate:self];
            munmap(hmdSafeModePtr, sizeof(HMDSafeModeStruct));
            hmdSafeModePtr = NULL;
            remove(hmdSafeModeTMPFilePath);
            free(hmdSafeModeTMPFilePath);
            hmdSafeModeTMPFilePath = NULL;
            hmdSafeModeAvailable = false;
            NSString *category = timeout?@"nomral_timeout":@"normal_config_request_finished";
            BOOL shouldTriggerEventTrace = NO;
            if (self.safeModeType == HMDSafeModeTypeMild) {
                category = timeout?@"mild_to_normal_timeout":@"mild_to_normal";
                shouldTriggerEventTrace = YES;
            } else if(self.safeModeType == HMDSafeModeTypeCritical) {
                category = timeout?@"critical_to_normal_timeout":@"critical_to_normal";
                shouldTriggerEventTrace = YES;
            }
            if (shouldTriggerEventTrace){
                id<HMDTTMonitorServiceProtocol> ttMonitor = hmd_get_heimdallr_ttmonitor();
                [ttMonitor hmdTrackService:@"hmd_sdk_safe_mode_invoke" metric:nil category:@{@"safe_mode_type":category} extra:nil];
            }
            HMDLog(@"safe mode check finish and clean tmp file with safe mode type %@", category);
            HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"safe mode check finish and clean tmp file with safe mode type %@", category);
        }
    });
}

#pragma mark HMDApplicationStatusChangeDelegate

- (void)applicationChangeToBackground {
    dispatch_on_heimdallr_queue(true, ^{
        if (hmdSafeModePtr != NULL) {
            hmdSafeModePtr->isBackground = true;
        }
    });
}

- (void)applicationChangeToForeground {
    dispatch_on_heimdallr_queue(true, ^{
        if (hmdSafeModePtr != NULL) {
            hmdSafeModePtr->isBackground = false;
        }
    });
}

@end
