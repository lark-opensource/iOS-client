//
//  BDPPackageInfoManager.h
//  Timor
//
//  Created by houjihu on 2020/5/24.
//

#import "BDPPackageInfoManager.h"
#import <FMDB/FMDB.h>
#import "BDPStorageManagerPackageInfoSQLDefine.h"
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/BDPCommonMonitorHelper.h>
#import <OPFoundation/EEFeatureGating.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>

@interface BDPPackageInfoManager ()

/// 应用类型
@property (nonatomic, assign) BDPType appType;
/// 包管理信息所在
@property (nonatomic, strong) FMDatabaseQueue *dbQueue;

@end

@implementation BDPPackageInfoManager

- (instancetype)initWithAppType:(BDPType)appType {
    if (self = [super init]) {
        self.appType = appType;
    }
    return self;
}

#pragma mark - Pkg Info Table

- (BDPPkgFileLoadStatus)queryPkgInfoStatusOfUniqueID:(BDPUniqueID *)uniqueID pkgName:(NSString *)pkgName {
    if (!uniqueID.isValid || !pkgName.length) {
        NSString *errorMessage = [NSString stringWithFormat:@"invalid id(%@) or packageName(%@)", uniqueID, pkgName];
        CommonMonitorWithCode(CommonMonitorCodePackage.pkg_install_invalid_params)
        .addTag(BDPTag.packageManager)
        .setErrorMessage(errorMessage)
        .flush();
        return BDPPkgFileLoadStatusUnknown;
    }
    __block NSUInteger bStatus = 0;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *set = [db executeQuery:SELECT_PKG_INFO_STATUS_STATEMENT, uniqueID.identifier, pkgName];
        if ([set next]) {
            bStatus = [set intForColumnIndex:0];
        }
        [set close];
    }];
    return bStatus;
}

- (NSArray<NSNumber *> *)queryPkgReadTypeOfUniqueID:(BDPUniqueID *)uniqueID pkgName:(NSString *)pkgName {
    if (!uniqueID.isValid || !pkgName.length) {
        NSString *errorMessage = [NSString stringWithFormat:@"invalid id(%@) or packageName(%@)", uniqueID, pkgName];
        CommonMonitorWithCode(CommonMonitorCodePackage.pkg_install_invalid_params)
        .addTag(BDPTag.packageManager)
        .setErrorMessage(errorMessage)
        .flush();
        return nil;
    }
    __block NSUInteger bReadType = -1;
    __block NSUInteger bFirstReadType = -1;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *set = [db executeQuery:SELECT_PKG_INFO_READTYPE_STATEMENT, uniqueID.identifier, pkgName];
        if ([set next]) {
            bReadType = [set intForColumnIndex:0];
            bFirstReadType = [set intForColumnIndex:1];
        }
        [set close];
    }];
    return @[@(bReadType), @(bFirstReadType)];
}

- (NSInteger)queryCountOfPkgInfoWithUniqueID:(BDPUniqueID *)uniqueID readType:(BDPPkgFileReadType)readType {
    if (!uniqueID.isValid) {
        NSString *errorMessage = [NSString stringWithFormat:@"invalid id(%@)", uniqueID];
        CommonMonitorWithCode(CommonMonitorCodePackage.pkg_install_invalid_params)
        .addTag(BDPTag.packageManager)
        .setErrorMessage(errorMessage)
        .flush();
        return 0;
    }
    __block NSInteger bCount = 0;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *set = [db executeQuery:SELECT_PKG_INFO_COUNT_OF_TYPE_STATEMENT, uniqueID.identifier, @(readType)];
        if ([set next]) {
            bCount = [set intForColumnIndex:0];
        }
        [set close];
    }];
    return bCount;
}

- (NSArray<NSString *> *)queryPkgNamesOfUniqueID:(BDPUniqueID *)uniqueID status:(BDPPkgFileLoadStatus)status {
    if (!uniqueID.isValid) {
        NSString *errorMessage = [NSString stringWithFormat:@"invalid id(%@)", uniqueID];
        CommonMonitorWithCode(CommonMonitorCodePackage.pkg_install_invalid_params)
        .addTag(BDPTag.packageManager)
        .setErrorMessage(errorMessage)
        .flush();
        return nil;
    }
    NSString *statement = SELECT_PKG_INFO_PACKAGE_NAMES_STATEMENT;
    __block NSMutableArray<NSString *> *pkgNames = [NSMutableArray<NSString *> array];
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *set = [db executeQuery:statement, uniqueID.identifier, @(status)];
        while ([set next]) {
            NSString *packageName = [set stringForColumnIndex:0];
            if (!BDPIsEmptyString(packageName)) {
                [pkgNames addObject:packageName];
            }
        }
        [set close];
    }];
    return [pkgNames copy];
}

- (void)replaceInToPkgInfoWithStatus:(NSUInteger)status withUniqueID:(BDPUniqueID *)uniqueID pkgName:(NSString *)pkgName readType:(BDPPkgFileReadType)readType {
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:UPDATE_ALL_PKG_INFO_STATEMENT, uniqueID.identifier, pkgName, @(status), @(readType), @(readType), @([[NSDate date] timeIntervalSince1970])];
    }];
}

- (void)updatePkgInfoStatus:(BDPPkgFileLoadStatus)status withUniqueID:(BDPUniqueID *)uniqueID pkgName:(NSString *)pkgName readType:(BDPPkgFileReadType)readType {
    if (!uniqueID.isValid || !pkgName.length) {
        NSString *errorMessage = [NSString stringWithFormat:@"invalid id(%@) or packageName(%@)", uniqueID, pkgName];
        CommonMonitorWithCode(CommonMonitorCodePackage.pkg_install_invalid_params)
        .addTag(BDPTag.packageManager)
        .setErrorMessage(errorMessage)
        .flush();
        return;
    }
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        //如果crash还是持续，通过FG降级到修改之前的逻辑
        if([EEFeatureGating boolValueForKey: @"openplatform.gadget.fmdbfix.downgrade"]) {
            [db executeUpdate:UPDATE_PKG_INFO_LOAD_STATUS_STATEMENT, @(status), @(readType), uniqueID.identifier, pkgName];
            return;
        }
        //
        FMResultSet *set = [db executeQuery:SELECT_PKG_INFO_READTYPE_STATEMENT, uniqueID.identifier, pkgName];
        BOOL recordExist = [set next];
        //When the result set is exhausted via -next, then the result set is automatically closed.
        //If you don't exhaust it, then you'll need to close it.
        //https://github.com/ccgus/fmdb/issues/692
        [set close];
        if(recordExist) {
            //有记录时选择更新（只更新，没有记录时不会创建。老逻辑）
            [db executeUpdate:UPDATE_PKG_INFO_LOAD_STATUS_STATEMENT, @(status), @(readType), uniqueID.identifier, pkgName];
        } else{
            //如果记录不存在，需要插入一条（REPLACE带插入功能）
            //理论上可以直接 REPLACE 代替 UPDATE，保守起见先保留原有逻辑
            [db executeUpdate:UPDATE_ALL_PKG_INFO_STATEMENT, uniqueID.identifier, pkgName, @(status), @(readType), @(readType), @([[NSDate date] timeIntervalSince1970])];
        }
    }];
}

- (void)updatePkgInfoAcessTimeWithStatus:(BDPPkgFileLoadStatus)status ofUniqueID:(BDPUniqueID *)uniqueID pkgName:(NSString *)pkgName readType:(BDPPkgFileReadType)readType {
    if (!uniqueID.isValid || !pkgName.length) {
        NSString *errorMessage = [NSString stringWithFormat:@"invalid id(%@) or packageName(%@)", uniqueID, pkgName];
        CommonMonitorWithCode(CommonMonitorCodePackage.pkg_install_invalid_params)
        .addTag(BDPTag.packageManager)
        .setErrorMessage(errorMessage)
        .flush();
        return;
    }
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:UPDATE_PKG_INFO_ACCESS_TIME, @(status), @(readType), @([[NSDate date] timeIntervalSince1970]), uniqueID.identifier, pkgName];
    }];
}

- (void)deletePkgInfoOfUniqueID:(BDPUniqueID *)uniqueID pkgName:(NSString *)pkgName {
    if (!uniqueID.isValid || !pkgName.length) {
        NSString *errorMessage = [NSString stringWithFormat:@"invalid id(%@) or packageName(%@)", uniqueID, pkgName];
        CommonMonitorWithCode(CommonMonitorCodePackage.pkg_install_invalid_params)
        .addTag(BDPTag.packageManager)
        .setErrorMessage(errorMessage)
        .flush();
        return;
    }
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:DELETE_PKG_INFO_STATEMENT, uniqueID.identifier, pkgName];
    }];
}

- (void)deletePkgInfosOfUniqueID:(BDPUniqueID *)uniqueID {
    if (!uniqueID.isValid) {
        NSString *errorMessage = [NSString stringWithFormat:@"invalid id(%@)", uniqueID];
        CommonMonitorWithCode(CommonMonitorCodePackage.pkg_install_invalid_params)
        .addTag(BDPTag.packageManager)
        .setErrorMessage(errorMessage)
        .flush();
        return;
    }
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:DELETE_PKG_INFOS_STATEMENT, uniqueID.identifier];
    }];
}

- (NSArray<NSString *> *)appIdsOfPkgBeyondLimit:(NSUInteger)limit withReadType:(BDPPkgFileReadType)readType {
    return [self appIdsOfPkgBeyondLimit:limit withReadType:readType isExcluded:NO];
}

- (NSArray<NSString *> *)appIdsOfPkgBeyondLimit:(NSUInteger)limit withExcludedReadType:(BDPPkgFileReadType)readType {
    return [self appIdsOfPkgBeyondLimit:limit withReadType:readType isExcluded:YES];
}

- (NSArray<NSString *> *)appIdsOfPkgBeyondLimit:(NSUInteger)limit withReadType:(BDPPkgFileReadType)readType isExcluded:(BOOL)isExcluded {
    if (limit > 0) {
        NSString *statement = isExcluded ? SELECT_PKG_INFO_ACCESS_DESC_EXCLUDE_LIMIT_STATEMENT : SELECT_PKG_INFO_ACCESS_DESC_LIMIT_STATEMENT;
        __block NSMutableArray *bAppIds = nil;
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *set = [db executeQuery:statement, @(readType), @(limit)];
            while ([set next]) {
                NSString *appId = [set stringForColumnIndex:0];
                if (appId.length) {
                    if (!bAppIds) {
                        bAppIds = [NSMutableArray array];
                    }
                    [bAppIds addObject:appId];
                }
            }
            [set close];
        }];
        return [bAppIds copy];
    }
    return nil;
}

- (void)clearPkgInfoTable {
    __block BOOL bResult;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        bResult = [db executeUpdate:DELETE_PKG_INFO_TABLE_STATEMENT];
    }];
    if (!bResult) {
        NSString *errorMessage = @"Clear table error: BDPPkgInfoTable";
        CommonMonitorWithCode(CommonMonitorCodePackage.pkg_install_failed)
        .addTag(BDPTag.packageManager)
        .setErrorMessage(errorMessage)
        .flush();
    }
    [self closeDBQueue];
}

- (void)closeDBQueue {
    if (_dbQueue != nil) {
        [_dbQueue close];
        _dbQueue = nil;
    }
}

/// 更新包的预安装信息; 
- (void)updatePackage:(nonnull BDPUniqueID *)uniqueID
              pkgName:(nonnull NSString *)pkgName
   prehandleSceneName:(nonnull NSString *)sceneName
    preUpdatePullType:(NSInteger)preUpdatePullType {
    if (!uniqueID.isValid || BDPIsEmptyString(pkgName) || BDPIsEmptyString(sceneName)) {
        BDPLogInfo(@"[Prehandle] params is invalid: %@, %@, %@", uniqueID, pkgName, sceneName);
        return;
    }

    NSMutableDictionary *dic = [[self extDictionary:uniqueID pkgName:pkgName] mutableCopy];

    if (!dic) {
        dic = [NSMutableDictionary dictionary];
    }

    dic[kPkgTableExtPrehandleSceneKey] = BDPSafeString(sceneName);
    dic[kPkgTableExtPreUpdatePullTypeKey] = @(preUpdatePullType);
    NSString *jsonString = [dic bdp_jsonString];

    BDPLogInfo(@"[Prehandle] new jsonString %@", jsonString);

    [self.dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:UPDATE_PKG_INFO_EXT_STATEMENT, BDPSafeString(jsonString), BDPSafeString(uniqueID.identifier), BDPSafeString(pkgName)];
    }];
}

- (void)updatePackageType:(BDPUniqueID *)uniqueID
                  pkgName:(NSString *)pkgName
            packageSource:(BDPPkgSourceType)pkgSource {
    if (!uniqueID.isValid || BDPIsEmptyString(pkgName)) {
        BDPLogInfo(@"params is invalid: %@, %@", uniqueID, pkgName);
        return;
    }

    NSMutableDictionary *dic = [[self extDictionary:uniqueID pkgName:pkgName] mutableCopy];

    if (!dic) {
        dic = [NSMutableDictionary dictionary];
    }

    dic[kPkgTableExtPkgSource] = @(pkgSource);
    NSString *jsonString = [dic bdp_jsonString];

    [self.dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:UPDATE_PKG_INFO_EXT_STATEMENT, BDPSafeString(jsonString), BDPSafeString(uniqueID.identifier), BDPSafeString(pkgName)];
    }];
}

/// 获取对应包在BDPPkgInfoTableV3中的ext字段, 该字段为JsonString, 该方法会转换成Dictionary
- (nullable NSDictionary *)extDictionary:(BDPUniqueID *)uniqueID pkgName:(NSString *)pkgName {
    NSString *extJsonString = [self extJsonString:uniqueID pkgName:pkgName];
    if (BDPIsEmptyString(extJsonString)) {
        BDPLogInfo(@"[Prehandle] extJsonString is nil for %@, pkg: %@", uniqueID.identifier, pkgName);
        return nil;
    }

    NSDictionary *dic = [NSDictionary bdp_dictionaryWithJsonString:extJsonString];
    return dic;
}

/// 获取对应包在BDPPkgInfoTableV3中的ext字段, 该字段为JsonString
- (nullable NSString *)extJsonString:(nonnull OPAppUniqueID *)uniqueID
                             pkgName:(nonnull NSString *)pkgName {
    if (!uniqueID.isValid || BDPIsEmptyString(pkgName)) {
        BDPLogInfo(@"[Prehandle] invalid params uniqueID: %@ pkg: %@", uniqueID, pkgName);
        return nil;
    }

    __block NSString *ext = nil;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *set = [db executeQuery:SELECT_PKG_INFO_EXT_STATEMENT, uniqueID.identifier, pkgName];
        if ([set next]) {
            ext = [set stringForColumnIndex:0];
        }
        [set close];
    }];

    return ext;
}

#pragma mark - Adpatation
- (BOOL)updateToPkgV2TableIfNeeded:(FMDatabase *)db {
    if (![db isKindOfClass:[FMDatabase class]]) {
        NSString *errorMessage = [NSString stringWithFormat:@"instance(%@) is not FMDatabase", db];
        CommonMonitorWithCode(CommonMonitorCodePackage.pkg_install_invalid_params)
        .addTag(BDPTag.packageManager)
        .setErrorMessage(errorMessage)
        .flush();
        return NO;
    }
    FMResultSet *result = [db executeQuery:SELECT_PKG_INFO_V1_TABLE];
    BOOL v1Exists = result.next && [result intForColumnIndex:0];
    BOOL v2Exists = NO;
    [result close];
    if (!v1Exists) {
        result = [db executeQuery:SELECT_PKG_INFO_V2_TABLE];
        v2Exists = result.next && [result intForColumnIndex:0];
        [result close];
    }
    BOOL success = NO;
    if (v1Exists) {
        success = [db executeUpdate:TRANSFER_PKG_INFO_FROM_V1];
        if (!success) {
            NSString *errorMessage = @"executeUpdate TRANSFER_PKG_INFO_FROM_V1 failed";
            CommonMonitorWithCode(CommonMonitorCodePackage.pkg_install_failed)
            .addTag(BDPTag.packageManager)
            .setErrorMessage(errorMessage)
            .flush();
            return NO;
        }
        success = [db executeUpdate:DROP_PKG_INFO_V1_TABLE];
        if (!success) {
            NSString *errorMessage = @"executeUpdate DROP_PKG_INFO_V1_TABLE failed";
            CommonMonitorWithCode(CommonMonitorCodePackage.pkg_install_failed)
            .addTag(BDPTag.packageManager)
            .setErrorMessage(errorMessage)
            .flush();
            return NO;
        }
    } else if (v2Exists) {
        success = [db executeUpdate:TRANSFER_PKG_INFO_FROM_V2];
        if (!success) {
            NSString *errorMessage = @"executeUpdate TRANSFER_PKG_INFO_FROM_V2 failed";
            CommonMonitorWithCode(CommonMonitorCodePackage.pkg_install_failed)
            .addTag(BDPTag.packageManager)
            .setErrorMessage(errorMessage)
            .flush();
            return NO;
        }
        success = [db executeUpdate:DROP_PKG_INFO_V2_TABLE];
        if (!success) {
            NSString *errorMessage = @"executeUpdate DROP_PKG_INFO_V2_TABLE failed";
            CommonMonitorWithCode(CommonMonitorCodePackage.pkg_install_failed)
            .addTag(BDPTag.packageManager)
            .setErrorMessage(errorMessage)
            .flush();
            return NO;
        }
    }
    return YES;
}

#pragma mark - property

- (FMDatabaseQueue *)dbQueue {
    @synchronized (self) {
        if (!_dbQueue) {
            _dbQueue = [BDPGetResolvedModule(BDPStorageModuleProtocol, _appType) sharedLocalFileManager].dbQueue;
            
            WeakSelf;
            [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                StrongSelfIfNilReturn;
                BOOL success = [db executeUpdate:CREATE_PKG_INFO_V3_TABLE];
                if (!success) {
                    *rollback = YES;
                    NSString *errorMessage = [NSString stringWithFormat:@"Create table error: BDPPkgInfoTable for appType(%@)", @(_appType)];
                    CommonMonitorWithCode(CommonMonitorCodePackage.pkg_install_failed)
                    .addTag(BDPTag.packageManager)
                    .setErrorMessage(errorMessage)
                    .flush();
                    return;
                }
                success = [self updateToPkgV2TableIfNeeded:db];
                if (!success) {
                    *rollback = YES;
                    NSString *errorMessage = [NSString stringWithFormat:@"updateToPkgV2TableIfNeeded for appType(%@)", @(_appType)];
                    CommonMonitorWithCode(CommonMonitorCodePackage.pkg_install_failed)
                    .addTag(BDPTag.packageManager)
                    .setErrorMessage(errorMessage)
                    .flush();
                    return;
                }
            }];
        }
    }
    return _dbQueue;
}

@end
