//
//  TMAKVStorage.m
//  Timor
//
//  Created by muhuai on 2018/4/11.
//

#import "TMAKVDatabase.h"
#import <ECOInfra/BDPLog.h>
#import <ECOInfra/BDPUtils.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import <ECOInfra/NSString+BDPExtension.h>
#import <FMDB/FMDB.h>

static const NSUInteger kLimitedSizeInBytes = 10 * 1024 * 1024;

static NSString *const DEFAULT_DB_NAME = @"database.sqlite";

static NSString *const CREATE_TABLE_SQL =
@"CREATE TABLE IF NOT EXISTS %@ ( \
id TEXT NOT NULL, \
json TEXT NOT NULL, \
PRIMARY KEY(id)) \
";

static NSString *const UPDATE_ITEM_SQL = @"REPLACE INTO %@ (id, json) values (?, ?)";

static NSString *const QUERY_ITEM_SQL = @"SELECT json from %@ where id = ? Limit 1";

static NSString *const SELECT_KEY_SQL = @"SELECT id from %@ where (id <> \"%@\") AND (id <> \"%@\")";

static NSString *const SELECT_ITEM_SQL = @"SELECT json from %@ where (id <> \"%@\") AND (id <> \"%@\")";

static NSString *const COUNT_ALL_SQL = @"SELECT count(*) as num from %@ where (id <> \"%@\") AND (id <> \"%@\")";

static NSString *const CLEAR_ALL_SQL = @"DELETE from %@";

static NSString *const DELETE_ITEM_SQL = @"DELETE from %@ where id = ?";

static NSString *const DELETE_ITEMS_SQL = @"DELETE from %@ where id in ( %@ )";

static NSString *const DELETE_ITEMS_WITH_PREFIX_SQL = @"DELETE from %@ where id like ? ";

static NSString *const DROP_TABLE_SQL = @" DROP TABLE '%@' ";

static NSString *const DEFAULT_JSON_KEY = @"default_json_key";

static NSString *const STORAGE_SIZE_KEY = @"__timor_storage_size_key__";

static NSString *const STORAGE_SIZE_JSON_KEY = @"size";

/// fix bug: 前期size计算错误，需要重新计算一遍，稳定之后删除掉
static NSString *const HAS_RECALCULATE_STORAGE_SIZE_KEY = @"__has_recalculate__timor_storage_size_key_v2__";

@implementation TMAKVItem

@end

@interface TMAKVStorage()

@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong) FMDatabaseQueue * dbQueue;

@end

@implementation TMAKVStorage

+ (TMAKVStorage *)storageForName:(NSString *)name dbQueue:(FMDatabaseQueue *)dbQueue {
    NSString * sql = [NSString stringWithFormat:CREATE_TABLE_SQL, name];
    __block BOOL result;
    [dbQueue inDatabase:^(FMDatabase *db) {
        NSError *error = nil;
        result = [db executeUpdate:sql values:nil error:&error];
        if (error) {
            BDPLogError(@"storageForName executeUpdate error %@", BDPParamStr(error, result, dbQueue, name));
        }
    }];
    if (!result) {
        BDPLogError(@"ERROR, failed to create table: %@", BDPParamStr(name, result, dbQueue, name));
        return nil;
    }
    TMAKVStorage *storage = [[TMAKVStorage alloc] init];
    storage.dbQueue = dbQueue;
    storage.name = name;
    return storage;
}

- (BOOL)setObject:(id)object forKey:(NSString *)key {
    return [self setObject:object forKey:key updateSize:YES];
}

- (BOOL)setObject:(id)object forKey:(NSString *)key updateSize:(BOOL)updateSize {
    if (![key isKindOfClass:[NSString class]] || !key.length) {
        return NO;
    }
    
    NSError *error;
    NSData *data;
    if ([NSJSONSerialization isValidJSONObject:object]) {
        data = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];
    } else {
        data = [NSJSONSerialization dataWithJSONObject:@{DEFAULT_JSON_KEY: object} options:0 error:&error];
    }
    
    if (error) {
        BDPLogError(@"Serialization error %@", BDPParamStr(error, _name, object));
        return NO;
    }
    
    NSString * jsonString = [[NSString alloc] initWithData:data encoding:(NSUTF8StringEncoding)];
    if (jsonString == nil) {
        BDPLogError(@"json string failed %@", BDPParamStr(_name, object));
        return NO;
    }
    NSString * sql = [NSString stringWithFormat:UPDATE_ITEM_SQL, _name];
    NSString *originJson = [self jsonItemForKey:key];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        NSError *error = nil;
        result = [db executeUpdate:sql values:@[key, jsonString] error:&error];
        if (error) {
            BDPLogError(@"setObject executeUpdate error %@", BDPParamStr(error, result, _name));
        }

    }];
    if (!result) {
        BDPLogError(@"ERROR, failed to insert/replace into table: %@", _name);
    } else if (updateSize) {
        NSUInteger originObjectSize = 0;
        if (originJson) {
            originObjectSize = [originJson lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        }
        NSUInteger objectSize = [jsonString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        NSInteger sizeToUpdate = objectSize - originObjectSize;
        [self updateStorageSize:sizeToUpdate isIncrese:YES];
    }
    return result;
}

- (id)objectForKey:(NSString *)key {
    TMAKVItem * item = [self KVItemForKey:key];
    if (item) {
        return item.value;
    } else {
        return nil;
    }
}

- (TMAKVItem *)KVItemForKey:(NSString *)objectId {
    if (BDPIsEmptyString(objectId)) {
        BDPLogError(@"objectId BDPIsEmptyString %@", BDPParamStr(objectId));
        return nil;
    }
    NSString *json = [self jsonItemForKey:objectId];
    if (json) {
        NSError * error = nil;
        id result = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding]
                                                    options:(NSJSONReadingAllowFragments) error:&error];
        if (error) {
            BDPLogError(@"ERROR, faild to prase to json %@", BDPParamStr(error, _name));
            return nil;
        }
        TMAKVItem * item = [[TMAKVItem alloc] init];
        item.key = objectId;
        item.value = result;
        if ([result isKindOfClass:[NSDictionary class]] && [result objectForKey:DEFAULT_JSON_KEY]) {
            item.value = [result objectForKey:DEFAULT_JSON_KEY];
        }
        return item;
    } else {
        return nil;
    }
}

- (NSString *)jsonItemForKey:(NSString *)objectId {
    NSString * sql = [NSString stringWithFormat:QUERY_ITEM_SQL, _name];
    __block NSString * json = nil;
    __block NSError *error = nil;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet * rs = [db executeQuery:sql values:@[objectId] error:&error];
        if ([rs next]) {
            json = [rs stringForColumn:@"json"];
        }
        [rs close];
    }];
    if (error) {
        BDPLogError(@"KVItemForKey executeQuery error %@", BDPParamStr(error, _name));
        return nil;
    }
    
    return json;
}

- (NSArray<NSString*> *)allKeys {
    NSString * sql = [NSString stringWithFormat:SELECT_KEY_SQL, _name, STORAGE_SIZE_KEY, HAS_RECALCULATE_STORAGE_SIZE_KEY];
    __block NSMutableArray * result = [NSMutableArray array];
    [_dbQueue inDatabase:^(FMDatabase *db) {
        NSError *error = nil;
        FMResultSet * rs = [db executeQuery:sql values:nil error:&error];
        if (error) {
            BDPLogError(@"allKeys executeQuery error %@", BDPParamStr(error, _name));
        }
        while ([rs next]) {
            NSString *key = [rs stringForColumn:@"id"];
            if (key) {
                [result addObject:key];
            }
        }
        [rs close];
    }];
    return result;
}

- (NSArray *)allJsonItems {
    NSString *sql = [NSString stringWithFormat:SELECT_ITEM_SQL , _name, STORAGE_SIZE_KEY, HAS_RECALCULATE_STORAGE_SIZE_KEY];
    __block NSMutableArray *result = [NSMutableArray array];
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql];
        while ([rs next]) {
            NSString *key = [rs stringForColumn:@"json"];
            if (key) {
                [result addObject:key];
            }
        }
    }];
    
    return result;
}

- (NSUInteger)getCount {
    NSString * sql = [NSString stringWithFormat:COUNT_ALL_SQL, _name, STORAGE_SIZE_KEY, HAS_RECALCULATE_STORAGE_SIZE_KEY];
    __block NSInteger num = 0;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet * rs = [db executeQuery:sql];
        if ([rs next]) {
            num = [rs unsignedLongLongIntForColumn:@"num"];
        }
        [rs close];
    }];
    return num;
}

- (BOOL)removeObjectForKey:(NSString *)key {
    if (BDPIsEmptyString(key)) {
        BDPLogError(@"key BDPIsEmptyString %@", BDPParamStr(key));
        return NO;
    }
    NSString *json = [self jsonItemForKey:key];
    NSString * sql = [NSString stringWithFormat:DELETE_ITEM_SQL, _name];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        NSError *error = nil;
        result = [db executeUpdate:sql values:@[key] error:&error];
        if (error) {
            BDPLogError(@"removeObjectForKey executeUpdate error %@", BDPParamStr(error, result, _name));
        }
    }];
    
    if (!result) {
        BDPLogError(@"ERROR, failed to delete item from table: %@", BDPParamStr(_name, result));
    } else {
        NSUInteger objectSize = [json lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        [self updateStorageSize:objectSize isIncrese:NO];
    }
    return result;
}

- (BOOL)removeAllObjects {
    NSString * sql = [NSString stringWithFormat:CLEAR_ALL_SQL, _name];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        NSError *error = nil;
        result = [db executeUpdate:sql values:nil error:&error];
        if (error) {
            BDPLogError(@"removeObjectForKey executeUpdate error %@", BDPParamStr(error, result, _name));
        }
    }];
    if (!result) {
        BDPLogError(@"ERROR, failed to clear table: %@", BDPParamStr(_name, result));
    }
    return result;
}


- (void)updateStorageSize:(NSInteger)changedSize isIncrese:(BOOL)increse {
    NSUInteger storageSize = [self storageSizeInBytes];
    NSInteger newSize = storageSize;
    if (increse) {
        newSize += changedSize;
    } else {
        newSize -= changedSize;
    }
    if (newSize < 0) {
        newSize = 0;
    }
    
    NSDictionary *objectDic = @{
                                STORAGE_SIZE_JSON_KEY: [NSString stringWithFormat:@"%lu", newSize]
                                };
    [self setObject:objectDic forKey:STORAGE_SIZE_KEY updateSize:NO];
}

- (NSUInteger)storageSizeInBytes {
    NSUInteger size = 0;
    NSDictionary *dic = [self objectForKey:STORAGE_SIZE_KEY];
    if (dic.count) {
        size = [dic bdp_unsignedIntegerValueForKey:STORAGE_SIZE_JSON_KEY];
        if (size < kLimitedSizeInBytes) {
            return size;
        }
    }
    
    size = [self calcStorageSizeInBytes];
    NSDictionary *objectDic = @{
                                STORAGE_SIZE_JSON_KEY: [NSString stringWithFormat:@"%lu", size]
                                };
    [self setObject:objectDic forKey:STORAGE_SIZE_KEY updateSize:NO];
    return size;
}

- (NSUInteger)calcStorageSizeInBytes {
    NSArray *items = [self allJsonItems];
    __block NSUInteger sizeInBytes = 0;
    [items enumerateObjectsUsingBlock:^(NSString *  _Nonnull json, NSUInteger idx, BOOL * _Nonnull stop) {
        NSUInteger bytes = [json lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        sizeInBytes += bytes;
    }];
    return sizeInBytes;
}

- (NSUInteger)limitSize {
    return kLimitedSizeInBytes;
}

@end

@interface TMAKVDatabase()

@property (strong, nonatomic) FMDatabaseQueue * dbQueue;

@end

@implementation TMAKVDatabase

- (id)initWithDBWithPath:(NSString *)dbPath {
    self = [super init];
    if (self) {
        if (_dbQueue) {
            [self close];
        }
        NSString *parentPath = dbPath.stringByDeletingLastPathComponent;
        // lint:disable lark_storage_check
        if (![[NSFileManager defaultManager] fileExistsAtPath:parentPath]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:parentPath withIntermediateDirectories:YES attributes:nil error:&error];
        }
        BOOL dbExist = [[NSFileManager defaultManager] fileExistsAtPath:dbPath];
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
        dbExist = [[NSFileManager defaultManager] fileExistsAtPath:dbPath];
        // lint:enable lark_storage_check
    }
    return self;
}

- (TMAKVStorage *)storageForName:(NSString *)name {
    return [TMAKVStorage storageForName:name dbQueue:self.dbQueue];
}

- (BOOL)dropStorage:(TMAKVStorage *)storage {
    NSString * sql = [NSString stringWithFormat:DROP_TABLE_SQL, storage.name];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        NSError *error = nil;
        result = [db executeUpdate:sql values:nil error:&error];
        if (error) {
            BDPLogError(@"dropStorage executeUpdate error %@", BDPParamStr(error, result, self.dbQueue, storage.name));
        }
    }];
    if (!result) {
        BDPLogError(@"ERROR, failed to drop table: %@", BDPParamStr(storage.name, result, _dbQueue));
    }
    return result;
}

- (void)close {
    [_dbQueue close];
    _dbQueue = nil;
}

@end
