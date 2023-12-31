//
//  ACCMomentDatabaseUpgradeManager.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/11/9.
//

#import "ACCMomentDatabaseUpgradeManager.h"
#import "ACCMomentMediaDataProvider.h"
#import "ACCMomentAlgorithmRecord.h"

#import <EffectPlatformSDK/EffectPlatform.h>
#import <EffectSDK_iOS/RequirementDefine.h>

static NSString *const ACCMomentDatabaseUpgradeManagerBIMCurrentVersionFileName = @"bim.curver";
static NSString *const ACCMomentDatabaseUpgradeManagerBIMNextVersionFileName = @"bim.nextver";

NSString *const kACCMomentDatabaseStartedUpgradeNotification = @"kACCMomentDatabaseStartedUpgradeNotification";
NSString *const kACCMomentDatabaseDidUpgradedNotification = @"kACCMomentDatabaseDidUpgradedNotification";

static NSString* ACCMomentServiceBIMCurrentVersionPath(void)
{
    return [ACCMomentMediaRootPath() stringByAppendingPathComponent:ACCMomentDatabaseUpgradeManagerBIMCurrentVersionFileName];
}

static NSString* ACCMomentServiceBIMNextVersionPath(void)
{
    return [ACCMomentMediaRootPath() stringByAppendingPathComponent:ACCMomentDatabaseUpgradeManagerBIMNextVersionFileName];
}


@interface ACCMomentDatabaseUpgradeManager ()

@end

@implementation ACCMomentDatabaseUpgradeManager

+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    static ACCMomentDatabaseUpgradeManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[ACCMomentDatabaseUpgradeManager alloc] init];
    });
    
    return manager;
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        ;
    }
    
    return self;
}

- (ACCMomentDatabaseUpgradeState)checkDatabaseUpgradeState
{
    NSDictionary *cmpDict = [NSKeyedUnarchiver unarchiveObjectWithFile:ACCMomentServiceBIMCurrentVersionPath()];
    NSDictionary *curDict = [ACCMomentDatabaseUpgradeManager transformDictFromOriginDict:[EffectPlatform checkoutModelInfosWithRequirements:@[@REQUIREMENT_MOMENT_TAG] modelNames:@{}]];
    
    ACCMomentDatabaseUpgradeState state = ACCMomentDatabaseUpgradeState_NoNeed;
    if ([[NSFileManager defaultManager] fileExistsAtPath:ACCMomentServiceBIMNextVersionPath()]) {
        state = ACCMomentDatabaseUpgradeState_IsUpgrading;
        
        NSDictionary *nextDict = [NSKeyedUnarchiver unarchiveObjectWithFile:ACCMomentServiceBIMNextVersionPath()];
        if ([ACCMomentDatabaseUpgradeManager bigVersionChange:nextDict compareVersion:curDict]) {
            state = ACCMomentDatabaseUpgradeState_NeedUpgrade;
        }
    } else if (cmpDict.allValues.count == 0 ||
               [ACCMomentDatabaseUpgradeManager bigVersionChange:cmpDict compareVersion:curDict]) {
        state = ACCMomentDatabaseUpgradeState_NeedUpgrade;
    }
    
    return state;
}

- (void)startDatabaseUpgrade
{
    if ([self checkDatabaseUpgradeState] == ACCMomentDatabaseUpgradeState_NeedUpgrade) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kACCMomentDatabaseStartedUpgradeNotification object:nil];
        // Write version to next version
        NSDictionary *saveVerions = [ACCMomentDatabaseUpgradeManager transformDictFromOriginDict:[EffectPlatform checkoutModelInfosWithRequirements:@[@REQUIREMENT_MOMENT_TAG] modelNames:@{}]];
        [NSKeyedArchiver archiveRootObject:saveVerions toFile:ACCMomentServiceBIMNextVersionPath()];
        
        [ACCMomentMediaDataProvider setNeedUpgradeDatabase];
    }
}

- (void)didCompletedDatabaseUpgrade
{
    if ([self checkDatabaseUpgradeState] == ACCMomentDatabaseUpgradeState_IsUpgrading) {
        [[NSFileManager defaultManager] removeItemAtPath:ACCMomentServiceBIMCurrentVersionPath() error:nil];
        [[NSFileManager defaultManager] moveItemAtPath:ACCMomentServiceBIMNextVersionPath() toPath:ACCMomentServiceBIMCurrentVersionPath() error:nil];
        
        [ACCMomentMediaDataProvider completeUpgradeDatabase];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kACCMomentDatabaseDidUpgradedNotification object:nil];
    }
}

#pragma mark - Utils
+ (NSDictionary<NSString *, ACCMomentAlgorithmRecord *> *)transformDictFromOriginDict:(NSDictionary<NSString *, IESAlgorithmRecord *> *)originDict
{
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    [originDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, IESAlgorithmRecord * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj.name isKindOfClass:NSString.class]) {
            result[obj.name] = [[ACCMomentAlgorithmRecord alloc] initWithOriginModel:obj];
        }
    }];
    
    return result;
}

+ (BOOL)bigVersionChange:(NSDictionary<NSString *, ACCMomentAlgorithmRecord *> *)version1 compareVersion:(NSDictionary<NSString *, ACCMomentAlgorithmRecord *> *)version2
{
    BOOL __block changeFlag = NO;
    [version1 enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, ACCMomentAlgorithmRecord * _Nonnull obj, BOOL * _Nonnull stop) {
        changeFlag = [self versionStringChange:obj.version withAnotherVersionString:version2[key].version];
        
        if (changeFlag == YES) {
            *stop = YES;
        }
    }];
    
    return changeFlag;
}

+ (BOOL)versionStringChange:(NSString *)verStr1 withAnotherVersionString:(NSString *)verStr2
{
    NSArray *strArr1 = [verStr1 componentsSeparatedByString:@"."];
    NSArray *strArr2 = [verStr2 componentsSeparatedByString:@"."];
    
    if (strArr1.firstObject && strArr2.firstObject) {
        return ![strArr1.firstObject isEqualToString:strArr2.firstObject];
    } else {
        return YES;
    }
}

@end
