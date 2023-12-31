//
//  Heimdallr+Cleanup.m
//  BDAlogProtocol
//
//  Created by 刘诗彬 on 2018/12/20.
//

#import "Heimdallr+Cleanup.h"
#import "Heimdallr+Private.h"
#import "HMDStoreCondition.h"
#import "HMDStoreIMP.h"
#import "HMDALogProtocol.h"

@implementation Heimdallr (Cleanup)

- (void)cleanupSessionFilesWithConfig:(HMDCleanupConfig *)cleanConfig path:(NSString *)rootPath
{
    @autoreleasepool {
        
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        NSArray <NSString *>*pathsArr = [fileMgr subpathsAtPath:rootPath];/*取得文件列表*/
        
        [pathsArr enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
            NSString *fileURL = [rootPath stringByAppendingPathComponent:obj];
            NSDictionary *fileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:fileURL error:nil];
            
            NSDate *fileDate = (NSDate *)[fileInfo objectForKey:NSFileCreationDate];
            BOOL timestampOutdated = [fileDate timeIntervalSince1970] < cleanConfig.outdatedTimestamp;
            if (timestampOutdated) {
                [[NSFileManager defaultManager] removeItemAtPath:fileURL error:NULL];
            }
        }];
    }
}

- (void)cleanupDatabaseWithConfig:(HMDCleanupConfig *)cleanConfig tableName:(NSString *)tablename {
    // 当第一次 Heimdallr 拉不到配置时 会在 HMDConfigManager.config 就为空了
    // 所以 HMDConfigManager.config.cleanupConfig 就是空的
    if (cleanConfig.andConditions.count > 0) {
        [[self database] deleteObjectsFromTable:tablename
                                                 andConditions:cleanConfig.andConditions
                                                  orConditions:nil];
    } else {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"%@", @"cleanupconditions cannot be nil!");
    }
}

- (void)cleanupDatabase:(NSString *)tablename limitSize:(NSUInteger)size {
    [self.database deleteObjectsFromTable:tablename limitToMaxSize:size];
}

+ (void)receiveDevastedDataForTableName:(NSString *)tableName localID:(__kindof NSNumber *)localID {
    if(tableName == nil || localID == nil) return;
    if(![localID isKindOfClass:NSNumber.class]) return;
    HMDStoreCondition *localIDCondtion = [[HMDStoreCondition alloc] init];
    localIDCondtion.key = @"localID";
    localIDCondtion.threshold = [localID doubleValue];
    localIDCondtion.judgeType = HMDConditionJudgeEqual;
    
    
    BOOL success = [[Heimdallr shared].database deleteObjectsFromTable:tableName andConditions:@[localIDCondtion] orConditions:nil];
    HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[Heimdallr receiveDevastedDataForTableName:%@ localID:%@] clean up %@", tableName, localID, success?@"success":@"failed");
}

@end
