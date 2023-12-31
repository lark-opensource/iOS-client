//
//  BDPMetaInfoManager.m
//  Timor
//
//  Created by houjihu on 2020/6/16.
//

#import "BDPMetaInfoAccessor.h"
#import "BDPStorageManager.h"
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import <FMDB/FMDB.h>

NSString * const kDBModelKey = @"model";
NSString * const tsKey = @"ts";

@interface BDPMetaInfoAccessor ()

/// 应用类型
@property (nonatomic, assign) BDPType appType;
/// meta管理信息所在数据库队列
@property (nonatomic, strong) FMDatabaseQueue *dbQueue;

@end

@implementation BDPMetaInfoAccessor

- (instancetype)initWithAppType:(BDPType)appType {
    if (self = [super init]) {
        self.appType = appType;
    }
    return self;
}

- (void)closeDBQueue {
    [_dbQueue close];
    _dbQueue = nil;
}

#pragma mark - Inuse Info Table
- (NSArray <NSDictionary *> *)getAllModelData {
    return [[self allInuseAppModel] arrayByAddingObjectsFromArray:[self allUpdateAppModel]];
}
- (NSArray <NSDictionary *> *)allInuseAppModel {
    __block NSMutableArray *allModels = [[NSMutableArray alloc] init];
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        //  拿inuse meta
        FMResultSet *rs = [db executeQuery:@"SELECT model,ts FROM BDPInuseInfoTable"];
        while ([rs next]) {
            NSData *modelData = [rs dataForColumn:kDBModelKey];
            BDPModel *appModel = [BDPStorageManager appModelFromData:modelData];
            NSNumber *ts = [NSNumber numberWithInteger:[rs longLongIntForColumn:tsKey]];
            if (appModel && ts) {
                NSDictionary *dic = @{
                    tsKey: ts,
                    kDBModelKey: appModel
                };
                [allModels addObject:dic];
            }
        }
        [rs close];
    }];
    return allModels;
}
- (NSArray <NSDictionary *> *)allUpdateAppModel {
    __block NSMutableArray *allModels = [[NSMutableArray alloc] init];
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        //  拿update meta
        FMResultSet *rs = [db executeQuery:@"SELECT model,ts FROM BDPUpdateInfoTable"];
        while ([rs next]) {
            NSData *modelData = [rs dataForColumn:kDBModelKey];
            BDPModel *appModel = [BDPStorageManager appModelFromData:modelData];
            NSNumber *ts = [NSNumber numberWithInteger:[rs longLongIntForColumn:tsKey]];
            if (appModel && ts) {
                NSDictionary *dic = @{
                    tsKey: ts,
                    kDBModelKey: appModel
                };
                [allModels addObject:dic];
            }
        }
        [rs close];
    }];
    return allModels;
}

#pragma mark - property

- (FMDatabaseQueue *)dbQueue {
    if (!_dbQueue) {
        _dbQueue = [BDPGetResolvedModule(BDPStorageModuleProtocol, _appType) sharedLocalFileManager].dbQueue;
    }
    return _dbQueue;
}

@end
