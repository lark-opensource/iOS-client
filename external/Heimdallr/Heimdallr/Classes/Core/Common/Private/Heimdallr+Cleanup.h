//
//  Heimdallr+Cleanup.h
//  BDAlogProtocol
//
//  Created by 刘诗彬 on 2018/12/20.
//

#import "Heimdallr.h"
#import "HMDCleanupConfig.h"

@interface Heimdallr (Cleanup)
- (void)cleanupSessionFilesWithConfig:(HMDCleanupConfig *)cleanConfig path:(NSString *)rootPath;
- (void)cleanupDatabaseWithConfig:(HMDCleanupConfig *)cleanConfig tableName:(NSString *)tablename;
- (void)cleanupDatabase:(NSString *)tablename limitSize:(NSUInteger)size;

/// 请判断 localID isKindOfClass: NSNumber.class 再调用方法
+ (void)receiveDevastedDataForTableName:(NSString *)tableName localID:(NSNumber *)localID;
@end
