//
//  HMDStoreFMDB.m
//  Heimdallr
//
//  Created by joy on 2018/6/12.
//

#import "HMDStoreFMDB.h"
#import "HMDBGDB.h"
#import "HMDFMDBConditionHelper.h"
#import "HMDBGTool.h"
#import "HMDMacro.h"
#import "HMDALogProtocol.h"

const unsigned long long kHMDDBFileSizeThreshold = 100 * HMD_MB;

@interface HMDStoreFMDB ()
@property (nonatomic, strong, readwrite) HMDBGDB *database;
@end


@implementation HMDStoreFMDB

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        self.database = [[HMDBGDB alloc] initWithPath:path];
    }
    
    return self;
}

- (NSString *)rootPath {
    return self.database.rootPath;
}

- (BOOL)createTable:(NSString *)tableName withClass:(__unsafe_unretained Class)cls {
    //获取"唯一约束"字段名
    NSArray* uniqueKeys = [HMDBGTool executeSelector:hmdbg_uniqueKeysSelector forClass:cls];
    //获取“联合主键”字段名
    NSArray* unionPrimaryKeys = [HMDBGTool executeSelector:hmdbg_unionPrimaryKeysSelector forClass:cls];
    //忽略的属性
    NSArray *ignoredKeys = [HMDBGTool executeSelector:hmdbg_ignoreKeysSelector forClass:cls];
    __block BOOL isExistTable = NO;
    
    [self.database isExistWithTableName:tableName complete:^(BOOL isExist) {
        isExistTable = isExist;
    }];
    
    if (!isExistTable){//如果不存在就新建
        NSArray* createKeys = [HMDBGTool bg_filtCreateKeys:[HMDBGTool getClassIvarList:cls onlyKey:NO] ignoredkeys:ignoredKeys];
        [self.database createTableWithTableName:tableName keys:createKeys unionPrimaryKeys:unionPrimaryKeys uniqueKeys:uniqueKeys complete:^(BOOL isSuccess) {
            isExistTable = isSuccess;
        }];
    }
    
    return isExistTable;
}

//add
- (BOOL)insertObject:(id)object
                into:(NSString *)tableName {
#ifdef DEBUG
    NSAssert([[HMDBGTool getTableNameWithObject:object] isEqualToString:tableName], @"There is a problem that the actual operation table is inconsistent with the intended table.");
#endif
    
    if (![self isTableExistsForName:tableName]) {
        BOOL tableExists = [self createTable:tableName withClass:[object class]];
        if (!tableExists) {
            return tableExists;
        }
    }
    
    __block BOOL insertSuccess = NO;
    NSArray *ignoreKeys = [HMDBGTool executeSelector:hmdbg_ignoreKeysSelector forClass:[object class]];
    [self.database saveObject:object ignoredKeys:ignoreKeys complete:^(BOOL isSuccess) {
        insertSuccess = isSuccess;
    }];
    
    return insertSuccess;
}

- (BOOL)insertObjects:(NSArray<id> *)objects
                 into:(NSString *)tableName {
    
    if (objects.count == 0) return NO;
    
    id object = [objects firstObject];
    
#ifdef DEBUG
    NSAssert([[HMDBGTool getTableNameWithObject:object] isEqualToString:tableName], @"There is a problem that the actual operation table is inconsistent with the intended table.");
#endif
    if (![self isTableExistsForName:tableName]) {
        BOOL tableExists = [self createTable:tableName withClass:[object class]];
        if (!tableExists) {
            return tableExists;
        }
    }
    __block BOOL insertSuccess = NO;
    NSArray *ignoreKeys = [HMDBGTool executeSelector:hmdbg_ignoreKeysSelector forClass:[object class]];
    [self.database saveObjects:objects ignoredKeys:ignoreKeys complete:^(BOOL isSuccess) {
        insertSuccess = isSuccess;
    }];
    
    return insertSuccess;
}

//query
- (id)getOneObjectWithTableName:(NSString *)tablename
                          class:(__unsafe_unretained Class)cls
                  andConditions:(NSArray<HMDStoreCondition *> *)andConditions
                   orConditions:(NSArray<HMDStoreCondition *> *)orConditions {
    if(!tablename || ![self isTableExistsForName:tablename]) {
        return nil;
    }
    NSMutableString *conditions = nil;

    if (andConditions || orConditions) {
        conditions = [NSMutableString stringWithFormat:@"WHERE %@",[HMDFMDBConditionHelper totalFMDBConditionWithAndList:andConditions orList:orConditions]];
    }
    
    __block NSArray* records;
    [self.database queryWithTableName:tablename conditions:conditions complete:^(NSArray * _Nullable array) {
        records = [HMDBGTool tansformDataFromSqlDataWithTableName:tablename class:cls array:array];
    }];

    if (records.count > 0) {
        return [records firstObject];
    }
    return nil;
}

- (NSArray<id> *)getAllObjectsWithTableName:(NSString *)tablename
                                      class:(__unsafe_unretained Class)cls {
    if(!tablename || ![self isTableExistsForName:tablename]) {
        return nil;
    }

    __block NSArray* records;
    [self.database queryWithTableName:tablename conditions:nil complete:^(NSArray * _Nullable array) {
        records = [HMDBGTool tansformDataFromSqlDataWithTableName:tablename class:cls array:array];
    }];
    
    return records;
}

- (NSArray<id> *)getObjectsWithTableName:(NSString *)tablename
                                   class:(__unsafe_unretained Class)cls
                           andConditions:(NSArray<HMDStoreCondition *> *)andConditions
                            orConditions:(NSArray<HMDStoreCondition *> *)orConditions {
    if(!tablename || ![self isTableExistsForName:tablename]) {
        return nil;
    }
    NSMutableString *conditions = nil;

    if (andConditions || orConditions) {
        conditions = [NSMutableString stringWithFormat:@"WHERE %@",[HMDFMDBConditionHelper totalFMDBConditionWithAndList:andConditions orList:orConditions]];
    }

    __block NSArray* records;
    [self.database queryWithTableName:tablename conditions:conditions complete:^(NSArray * _Nullable array) {
        records = [HMDBGTool tansformDataFromSqlDataWithTableName:tablename class:cls array:array];
    }];
    
    return records;
}

- (NSArray<id> *)getObjectsWithTableName:(NSString *)tablename
                                   class:(__unsafe_unretained Class)cls
                           andConditions:(NSArray<HMDStoreCondition *> *)andConditions
                            orConditions:(NSArray<HMDStoreCondition *> *)orConditions
                        orderingProperty:(NSString *)orderingProperty
                            orderingType:(HMDConditionOrder)orderingType {
    if(!tablename || ![self isTableExistsForName:tablename]) {
        return nil;
    }
    NSMutableString *conditions = nil;
    
    if (andConditions || orConditions) {
        NSString *filterCondition = [HMDFMDBConditionHelper totalFMDBConditionWithAndList:andConditions orList:orConditions];
        if (filterCondition) {
            conditions = [NSMutableString stringWithFormat:@"WHERE %@",filterCondition];
        }
    }
    
    if (orderingType == HMDOrderDescending) {
        if (conditions) {
            [conditions appendFormat:@"ORDER BY %@ DESC",orderingProperty];
        } else {
            conditions = [NSMutableString stringWithFormat:@"ORDER BY %@ DESC",orderingProperty];
        }
    }
    if (orderingType == HMDOrderAscending) {
        if (conditions) {
            [conditions appendFormat:@"ORDER BY %@ ASC",orderingProperty];
        } else {
            conditions = [NSMutableString stringWithFormat:@"ORDER BY %@ ASC",orderingProperty];
        }
    }
    
    __block NSArray* records;
    [self.database queryWithTableName:tablename conditions:conditions complete:^(NSArray * _Nullable array) {
        records = [HMDBGTool tansformDataFromSqlDataWithTableName:tablename class:cls array:array];
    }];
    
    return records;
}
- (NSArray<id> *)getObjectsWithTableName:(NSString *)tablename
                                   class:(__unsafe_unretained Class)cls
                           andConditions:(NSArray<HMDStoreCondition *> *)andConditions
                            orConditions:(NSArray<HMDStoreCondition *> *)orConditions
                                   limit:(NSInteger)limitCount {
    if(!tablename || ![self isTableExistsForName:tablename]) {
        return nil;
    }
    NSMutableString *totalconditions = nil;
    NSString *conditions = nil;
    
    if (andConditions || orConditions) {
        conditions = [HMDFMDBConditionHelper totalFMDBConditionWithAndList:andConditions orList:orConditions];
    }
    
    if (limitCount) {
        if (conditions) {
            totalconditions = [NSMutableString stringWithFormat:@"WHERE localID IN (SELECT localID FROM %@ WHERE %@ LIMIT %ld)" ,tablename, conditions, (long)limitCount];
        } else {
            totalconditions = [NSMutableString stringWithFormat:@"WHERE localID IN (SELECT localID FROM %@ LIMIT %ld)" ,tablename, (long)limitCount];
        }
    } else {
        totalconditions = [NSMutableString stringWithFormat:@"WHERE %@",conditions];
    }
    
    __block NSArray* records;
    [self.database queryWithTableName:tablename conditions:totalconditions complete:^(NSArray * _Nullable array) {
        records = [HMDBGTool tansformDataFromSqlDataWithTableName:tablename class:cls array:array];
    }];
    
    return records;
}

//delete
- (BOOL)deleteAllObjectsFromTable:(NSString *)tableName {
    if (!tableName || ![self isTableExistsForName:tableName]) {
        return NO;
    }
    __block BOOL success = NO;
    [self.database deleteWithTableName:tableName conditions:nil complete:^(BOOL isSuccess) {
        success = isSuccess;
    }];
    return success;
}

- (BOOL)dropTable:(NSString *)tableName {
    if (!tableName || ![self isTableExistsForName:tableName]) {
        return NO;
    }
    __block BOOL success = NO;
    [self.database dropTable:tableName complete:^(BOOL isSuccess) {
        success = isSuccess;
    }];
    return success;
}

- (BOOL)deleteObjectsFromTable:(NSString *)tableName
                limitToMaxSize:(long long)maxSize {
    //保护，防止误删
    if (maxSize == 0) {
        return NO;
    }
    
    if (!tableName || ![self isTableExistsForName:tableName]) {
        return NO;
    }
    
    long long currentSize = [self recordCountForTable:tableName];
    
    
    if (currentSize <= maxSize) {
        return NO;
    }
    
    __block BOOL success = NO;
    
    long long eliminatingCount = currentSize - maxSize;
    
    //满的时候先删旧数据
    NSString *conditions = [NSString stringWithFormat:@"WHERE localID IN (SELECT localID FROM %@ ORDER BY localID ASC LIMIT %lld)" ,tableName, eliminatingCount];
    
    [self.database deleteWithTableName:tableName conditions:conditions complete:^(BOOL isSuccess) {
        success = isSuccess;
    }];
    return success;
}

- (BOOL)deleteObjectsFromTable:(NSString *)tableName
                 andConditions:(NSArray<HMDStoreCondition *> *)andConditions
                  orConditions:(NSArray<HMDStoreCondition *> *)orConditions {
    if (!tableName || ![self isTableExistsForName:tableName]) {
        return NO;
    }
    
    //两者均为空会将整个表中的数据全部删除，这里做一个异常保护
    if(!andConditions && !orConditions) {
        return NO;
    }

    NSMutableString *conditions = nil;
    
    if (andConditions || orConditions) {
        NSString *filterCondition = [HMDFMDBConditionHelper totalFMDBConditionWithAndList:andConditions orList:orConditions];
        if (filterCondition) {
            conditions = [NSMutableString stringWithFormat:@"WHERE %@",filterCondition];
        }
    }
    
    __block BOOL success = NO;
    [self.database deleteWithTableName:tableName conditions:conditions complete:^(BOOL isSuccess) {
        success = isSuccess;
    }];
    
    // 磁盘空间满了，先清理wal文件，再重试一次
    if (!success && [self deleteErrorCode] == 13) {
        [self executeCheckpoint];
        [self.database deleteWithTableName:tableName conditions:conditions complete:^(BOOL isSuccess) {
            success = isSuccess;
        }];
    }

    return success;
}
- (BOOL)deleteObjectsFromTable:(NSString *)tableName
                 andConditions:(NSArray<HMDStoreCondition *> *)andConditions
                  orConditions:(NSArray<HMDStoreCondition *> *)orConditions
                         limit:(NSInteger)limitCount {
    if (!tableName || ![self isTableExistsForName:tableName]) {
        return NO;
    }
    NSMutableString *totalconditions = nil;
    NSString *conditions = nil;
    
    if (andConditions || orConditions) {
        conditions = [HMDFMDBConditionHelper totalFMDBConditionWithAndList:andConditions orList:orConditions];
    }
    if (limitCount) {
        if (conditions) {
            totalconditions = [NSMutableString stringWithFormat:@"WHERE localID IN (SELECT localID FROM %@ WHERE %@ LIMIT %ld)" ,tableName, conditions, (long)limitCount];
        } else {
            totalconditions = [NSMutableString stringWithFormat:@"WHERE localID IN (SELECT localID FROM %@ LIMIT %ld)" ,tableName, (long)limitCount];
        }
    } else {
        totalconditions = [NSMutableString stringWithFormat:@"WHERE %@",conditions];
    }
    
    __block BOOL success = NO;
    [self.database deleteWithTableName:tableName conditions:totalconditions complete:^(BOOL isSuccess) {
        success = isSuccess;
    }];

    return success;
}

//update
- (BOOL)updateRowsInTable:(NSString *)tableName
               onProperty:(NSString *)property
            propertyValue:(id)propertyValue
               withObject:(id)object
            andConditions:(NSArray<HMDStoreCondition *> *)andConditions
             orConditions:(NSArray<HMDStoreCondition *> *)orConditions {
#ifdef DEBUG
    NSAssert([[HMDBGTool getTableNameWithObject:object] isEqualToString:tableName], @"There is a problem that the actual operation table is inconsistent with the intended table");
#endif
    if (!tableName || ![self isTableExistsForName:tableName]) {
        return NO;
    }
    NSString *conditions = nil;
    NSString *filterCondition = [HMDFMDBConditionHelper totalFMDBConditionWithAndList:andConditions orList:orConditions];
    
    __block BOOL success = NO;
    
    if (filterCondition) {
        conditions = [NSMutableString stringWithFormat:@"WHERE %@",filterCondition];
        [self.database updateObject:object propertyName:property propertyValue:propertyValue conditions:conditions complete:^(BOOL isSuccess) {
            success = isSuccess;
        }];
    }
    return success;
}

//update
- (BOOL)updateRowsInTable:(NSString *)tableName
               onProperty:(NSString *)property
            propertyValue:(id)propertyValue
               withObject:(id)object
            andConditions:(NSArray<HMDStoreCondition *> *)andConditions
             orConditions:(NSArray<HMDStoreCondition *> *)orConditions
                    limit:(NSInteger)limitCount {
#ifdef DEBUG
    NSAssert([[HMDBGTool getTableNameWithObject:object] isEqualToString:tableName], @"There is a problem that the actual operation table is inconsistent with the intended table.");
#endif
    if (!tableName || ![self isTableExistsForName:tableName]) {
        return NO;
    }
    NSMutableString *totalconditions = nil;
    NSString *conditions = nil;
    
    if (andConditions || orConditions) {
        conditions = [HMDFMDBConditionHelper totalFMDBConditionWithAndList:andConditions orList:orConditions];
    }
    if (limitCount) {
        if (conditions) {
            totalconditions = [NSMutableString stringWithFormat:@"WHERE localID IN (SELECT localID FROM %@ WHERE %@ LIMIT %ld)" ,tableName, conditions, (long)limitCount];
        } else {
            totalconditions = [NSMutableString stringWithFormat:@"WHERE localID IN (SELECT localID FROM %@ LIMIT %ld)" ,tableName, (long)limitCount];
        }
    } else {
        totalconditions = [NSMutableString stringWithFormat:@"WHERE %@",conditions];
    }
    __block BOOL success = NO;
    [self.database updateObject:object propertyName:property propertyValue:propertyValue conditions:totalconditions complete:^(BOOL isSuccess) {
        success = isSuccess;
    }];
    return success;
}

// update
- (BOOL)updateRowsInTable:(NSString *)tableName
          checkIvarChange:(BOOL)checkIvarChange
               onProperty:(NSString *)property
            propertyValue:(id)propertyValue
               withObject:(id)object
            andConditions:(NSArray<HMDStoreCondition *> *)andConditions
             orConditions:(NSArray<HMDStoreCondition *> *)orConditions {
    
    if (!tableName || ![self isTableExistsForName:tableName]) {
        return NO;
    }
    NSString *conditions = nil;
    NSString *filterCondition = [HMDFMDBConditionHelper totalFMDBConditionWithAndList:andConditions orList:orConditions];
    
    __block BOOL success = NO;
    
    if (filterCondition) {
        conditions = [NSMutableString stringWithFormat:@"WHERE %@",filterCondition];
        [self.database updateObject:object checkIvarChanged:checkIvarChange propertyName:property propertyValue:propertyValue conditions:conditions complete:^(BOOL isSuccess) {
            success = isSuccess;
        }];
    }
    return success;
}

- (BOOL)isTableExistsForName:(NSString *)tableName {
    return [self.database bg_isExistWithTableName:tableName];
}

- (void)vacuumIfNeeded {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        unsigned long long filesize = [self dbFileSize];
        if (filesize > kHMDDBFileSizeThreshold) {
            [self.database vacuumDB];
            
            if (hmd_log_enable()) {
                unsigned long long cleanedFileSize = [self dbFileSize];
                NSString *warningLog = [NSString stringWithFormat:@"APM DB size exceeded 50MB，triggered auto cleaning, before clearance size:%lldbyte, after clearance size：%lldbyte",filesize,cleanedFileSize];
                HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"%@",warningLog)
            }
        }
    });
}

- (void)executeCheckpoint {
    [self.database executeCheckpoint];
}

- (void)immediatelyActiveVacuum {
    [self.database vacuumDB];
}

- (unsigned long long)dbFileSize {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *dbPath = self.database.rootPath;
    unsigned long long filesize = 0;
    if ([fileManager fileExistsAtPath:dbPath]) {
        NSDictionary *fileDic = [fileManager attributesOfItemAtPath:dbPath error:nil];//获取文件的属性
        filesize = [[fileDic objectForKey:NSFileSize] longLongValue];
    }
    
    return filesize;
}

- (long long)recordCountForTable:(NSString *)tableName {
    return [self.database countForTable:tableName where:nil];
}

- (long long)recordCountForTable:(NSString *)tableName andConditions:(NSArray<HMDStoreCondition *> *)andConditions orConditions:(NSArray<HMDStoreCondition *> *)orConditions {
    if(!tableName || ![self isTableExistsForName:tableName]) {
        return -1;
    }
    
    NSMutableString *conditions = nil;
    if (andConditions || orConditions) {
        conditions = [NSMutableString stringWithFormat:@"WHERE %@",[HMDFMDBConditionHelper totalFMDBConditionWithAndList:andConditions orList:orConditions]];
    }
    
    return [self.database countForTable:tableName conditions:conditions];
}

//事务操作
-(void)inTransaction:(BOOL (^_Nonnull)(void))block {
    [self.database inTransaction:block];
}

- (NSInteger)deleteErrorCode {
    return self.database.deleteErrorCode;
}

- (void)closeDB {
    [self.database closeDB];
}

@end
