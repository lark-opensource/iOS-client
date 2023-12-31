//
//  HMDBaseModule.m
//  Heimdallr-8bda3036
//
//  Created by 崔晓兵 on 6/6/2022.
//

#import "HMDBaseModule.h"
#import "HMDRecordStore.h"
#import "HMDStoreCondition.h"
#import "HMDHermasHelper.h"
#import "HMDNetworkReqModel.h"
#import "HMDNetworkManager.h"
#import "HMDStoreIMP.h"
#import "HMDCleanupConfig.h"
#import "HMDHeimdallrConfig.h"
#import "HMDInjectedInfo.h"
#import "HMDRecordStoreObject.h"
#import "HMDUploadHelper.h"
#import "HMDDebugRealConfig.h"
#import "HMDALogProtocol.h"
#import "HMDUserDefaults.h"
#import "HMDMacro.h"
#import "HMDJSON.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

static NSInteger const kUploadLimictCount = 200;
static double const kMigrateExpiredInterval = 7 * 24 * 60 * 60;
static NSString * const kMigrateRemoveFinished = @"kMigrateRemoveFinished";
static NSString * const kMigrateReportFinished = @"kMigrateReportFinished";

@protocol HMDBaseModuleFakeDelegate <NSObject>
- (NSDictionary *)reportDictionary;
@end


@implementation HMDBaseModule

- (instancetype)init {
    if (self = [super init]) {
        _database = [HMDRecordStore shared].database;
        _operationRecords = @[].mutableCopy;
        NSNumber *recordThreadShareMaskNumber = [[HMDUserDefaults standardUserDefaults] objectForKey:@"record_thread_share_mask"];
        _recordThreadShareMask = recordThreadShareMaskNumber ? [recordThreadShareMaskNumber integerValue] : 14;
    }
    return self;
}

#pragma mark - HMDMigrateProtocol

- (void)migrateForward {
    // clean rollback mark of hermas
    [[HMEngine sharedEngine] cleanRollbackMigrateMark:self.config.name];
    
    // migrate forward by heimdallr
    // remove expired data first
    [self removeHeimdallrExpiredData];
    
    // report data who's enable_upload == 1
    [self reportHeimdallrNeedUploadedData];
}

- (void)migrateBack {
    // clean migrate mark of heimdallr
    NSString *key = [NSString stringWithFormat:@"%@_%@", kMigrateRemoveFinished, NSStringFromClass([self class])];
    [HMDHermasHelper.customUserDefault setValue:nil forKey:key];
    key = [NSString stringWithFormat:@"%@_%@", kMigrateReportFinished, NSStringFromClass([self class])];
    [HMDHermasHelper.customUserDefault setValue:nil forKey:key];
    
    // migrate back by hermas
    [[HMEngine sharedEngine] migrateDataWithModuleId:self.config.name];
}

#pragma mark - Migration

- (void)removeHeimdallrExpiredData {
    NSString *key = [NSString stringWithFormat:@"%@_%@", kMigrateRemoveFinished, NSStringFromClass([self class])];
    if ([[HMDHermasHelper.customUserDefault valueForKey:key] boolValue]) {
        return;
    }
    
    NSString *timeKey = [NSString stringWithFormat:@"%@_%@_begintime", kMigrateRemoveFinished, NSStringFromClass([self class])];
    if (![HMDHermasHelper.customUserDefault valueForKey:timeKey]) {
        [HMDHermasHelper.customUserDefault setValue:[NSDate date] forKey:timeKey];
    }
    
    NSDate *date = [HMDHermasHelper.customUserDefault valueForKey:timeKey];
    if ([NSDate date].timeIntervalSince1970 - date.timeIntervalSince1970 > kMigrateExpiredInterval) {
        NSString *key = [NSString stringWithFormat:@"%@_%@", kMigrateRemoveFinished, NSStringFromClass([self class])];
        [HMDHermasHelper.customUserDefault setValue:@(YES) forKey:key];
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr Migration", @"Remove Heimdallr expired data finished");
        return;
    }
    
    NSArray *andConditions = self.heimdallrConfig.cleanupConfig.andConditions;
    if (andConditions.count <= 0) return;
    [self.dataBaseTableMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull tableName, Class  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([self.database isTableExistsForName:tableName]) {
            [self.database deleteObjectsFromTable:tableName andConditions:andConditions orConditions:nil];
        }
    }];
}

- (void)reportHeimdallrNeedUploadedData {
    // if the migration has been finished, return
    NSString *key = [NSString stringWithFormat:@"%@_%@", kMigrateReportFinished, NSStringFromClass([self class])];
    if ([HMDHermasHelper.customUserDefault boolForKey:key]) return;
    
    @autoreleasepool {
        NSArray *data = [self fetchDataFromDatabase];
        if (data.count == 0) {
            [HMDHermasHelper.customUserDefault setBool:YES forKey:key];
            HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr Migration", @"report Heimdallr data (enable_upload = 1) finished");
            return;
        }
        
        __weak __typeof(self) wself = self;
        [self reportData:data callback:^(BOOL success) {
            __strong __typeof(wself) sself = wself;
            @autoreleasepool {
                [sself dataDidReportSuccess:success];
            }
        }];
    }

}

- (void)dataDidReportSuccess:(BOOL)success {
    if (success) {
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr Migration", @"report Heimdallr data (enable_upload = 1)");
        [self.operationRecords enumerateObjectsUsingBlock:^(HMDDatabaseOperationRecord * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.database deleteObjectsFromTable:obj.tableName andConditions:obj.andConditions orConditions:obj.orConditions limit:obj.limitCount];
        }];
    }
    [self.operationRecords removeAllObjects];
    
    [self reportHeimdallrNeedUploadedData];
}



- (NSArray *)conditionArrayWithTableName:(NSString *)recordClassName {
    NSMutableArray *conditions = @[].mutableCopy;
    
    if ([self shouldCareEnableUpload:recordClassName]) {
        HMDStoreCondition *condition0 = [[HMDStoreCondition alloc] init];
        condition0.key = @"enableUpload";
        condition0.threshold = 0;
        condition0.judgeType = HMDConditionJudgeGreater;
        [conditions addObject:condition0];
    }
    
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"timestamp";
    condition1.threshold = [[NSDate date] timeIntervalSince1970];
    condition1.judgeType = HMDConditionJudgeLess;
    [conditions addObject:condition1];
    
    return conditions;
}

- (id)fetchDataFromDatabase {
    NSMutableArray *records = @[].mutableCopy;
    __block NSInteger limitCount = kUploadLimictCount;
    [self.dataBaseTableMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull tableName, Class _Nonnull cls, BOOL * _Nonnull stop) {
        if (![self.database isTableExistsForName:tableName]) {
            return;
        }
        NSArray *dataAndConditions = [self conditionArrayWithTableName:NSStringFromClass(cls)];
        NSArray *temp = [self.database getObjectsWithTableName:tableName
                                                         class:cls
                                                 andConditions:dataAndConditions
                                                  orConditions:nil
                                                         limit:limitCount];
        
        // aggregate if needed
        if (temp.count == 0) return;
        id record = temp.firstObject;
        CLANG_DIAGNOSTIC_PUSH
        CLANG_DIAGNOSTIC_IGNORE_UNDECLARED_SELECTOR
        BOOL needAggregate = [record respondsToSelector:@selector(needAggregate)] && [record performSelector:@selector(needAggregate)];
        if (needAggregate && [cls respondsToSelector:@selector(aggregateDataWithRecords:)]) {
            temp = [cls aggregateDataWithRecords:temp];
        }
        CLANG_DIAGNOSTIC_POP
        [records addObjectsFromArray:temp];
        
        // record operation
        HMDDatabaseOperationRecord *operationRecord = [[HMDDatabaseOperationRecord alloc] init];
        operationRecord.tableName = tableName;
        operationRecord.andConditions = dataAndConditions;
        operationRecord.limitCount = limitCount;
        [self.operationRecords addObject:operationRecord];
        
        // update limit count
        limitCount -= temp.count;
        if (records.count >= limitCount) {
            *stop = YES;
        }
    }];
    
    if ([self isKindOfClass:NSClassFromString(@"HMDPerformanceModule")]) {
        NSDictionary<NSString *, NSMutableArray *> *recordDic = @{}.mutableCopy;
        Class ttMonitorRecordClass = NSClassFromString(@"HMDTTMonitorRecord");
        [records enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *appId = [HMDInjectedInfo defaultInfo].appID;
            if ([obj isKindOfClass:ttMonitorRecordClass]) {
                appId = [obj appID];
            }
            if (![recordDic valueForKey:appId]) {
                [recordDic setValue:@[].mutableCopy forKey:appId];
            }
            NSMutableArray *mutableArr = [recordDic valueForKey:appId];
            if ([obj isKindOfClass:NSDictionary.class]) {
                [mutableArr addObject:obj];
            } else {
                [mutableArr addObject:[obj reportDictionary]];
            }
        }];
        
        NSMutableArray *result = @[].mutableCopy;
        [recordDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray * _Nonnull obj, BOOL * _Nonnull stop) {
            if (obj != nil) {
                NSMutableDictionary *header = [[HMDUploadHelper sharedInstance].headerInfo mutableCopy];
                [header setValue:key forKey:@"aid"];
                
                NSMutableDictionary *dic = @{}.mutableCopy;
                [dic setValue:obj forKey:@"data"];
                [dic setValue:header forKey:@"header"];
                [result addObject:dic];
            }
        }];
        return result;
    } else {
        NSMutableDictionary *header = [[HMDUploadHelper sharedInstance].headerInfo mutableCopy];
        NSMutableArray *mutableArr = @[].mutableCopy;
        [records enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:NSDictionary.class]) {
                [mutableArr addObject:obj];
            } else {
                [mutableArr addObject:[obj reportDictionary]];
            }
        }];
        if (mutableArr.count == 0) {
            return nil;
        }
        NSMutableDictionary *dic = @{}.mutableCopy;
        [dic setValue:mutableArr forKey:@"data"];
        [dic setValue:header forKey:@"header"];
        return @[dic];
    }
}

- (NSDictionary<NSString *, Class> *)dataBaseTableMap {
    return nil;
}

- (BOOL)shouldCareEnableUpload:(NSString *)recordClassName {
    return YES;
}

- (void)reportData:(id)dataArray callback:(void(^)(BOOL success))callback {
    NSMutableDictionary * headerDict = [NSMutableDictionary dictionaryWithCapacity:3];
    [headerDict setValue:@"application/json; encoding=utf-8" forKey:@"Content-Type"];
    [headerDict setValue:@"application/json" forKey:@"Accept"];
    [headerDict setValue:@"1" forKey:@"Version-Code"];
    [headerDict setValue:@"2085" forKey:@"sdk_aid"];
    
    
    NSDictionary *body = @{@"list":[dataArray copy]};
    
    HMDNetworkReqModel *reqModel = [HMDNetworkReqModel new];
    reqModel.requestURL = [HMDHermasHelper urlStringWithHost:self.config.domain path:self.config.path];
    reqModel.method = @"POST";
    reqModel.headerField = [headerDict copy];
    reqModel.params = body;
    reqModel.needEcrypt = self.config.enableEncrypt;
    [[HMDNetworkManager sharedInstance] asyncRequestWithModel:reqModel callback:^(NSError *error, id maybeDictionary) {
        // 简单处理：只要error为空，就认为是成功
        if (callback) callback(error ? NO : YES);
    }];
}


#pragma mark - HMDExternalSearchProtocol

- (NSArray *)getDataWithParam:(HMSearchParam *)param {
    if (![self.config.name isEqualToString:param.moduleId]) return nil;
    if (!param.userInfo) return nil;
    
    HMDDebugRealConfig *config = (HMDDebugRealConfig *)param.userInfo;
    
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"timestamp";
    condition1.threshold = config.fetchStartTime;
    condition1.judgeType = HMDConditionJudgeGreater;
    
    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key = @"timestamp";
    condition2.threshold = config.fetchEndTime;
    condition2.judgeType = HMDConditionJudgeLess;
    
    NSArray<HMDStoreCondition *> *debugRealCondition = @[condition1,condition2];
    self.debugRealCondition = debugRealCondition;
    
    NSMutableArray *records = @[].mutableCopy;
    
    [self.dataBaseTableMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull tableName, Class _Nonnull cls, BOOL * _Nonnull stop) {
        if (![self.database isTableExistsForName:tableName]) {
            return;
        }
        
        NSArray *temp = [self.database getObjectsWithTableName:tableName class:cls andConditions:debugRealCondition orConditions:nil limit:config.limitCnt];
        
        [temp enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [records addObject:[obj reportDictionary]];
        }];
    }];
    
    return records;
}

- (void)removeDataWithParam:(HMSearchParam *)param {
    if (![self.config.name isEqualToString:param.moduleId]) return;
    if (!param.userInfo) return;
    HMDDebugRealConfig *config = (HMDDebugRealConfig *)param.userInfo;
    [self.dataBaseTableMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull tableName, Class _Nonnull cls, BOOL * _Nonnull stop) {
        if (![self.database isTableExistsForName:tableName]) {
            return;
        }
        [self.database deleteObjectsFromTable:tableName andConditions:self.debugRealCondition orConditions:nil limit:config.limitCnt];
    }];
    self.debugRealCondition = nil;
}


@end
