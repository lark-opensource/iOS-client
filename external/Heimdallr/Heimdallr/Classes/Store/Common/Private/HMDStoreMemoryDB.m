//
//	HMDStoreMemoryDB.m
// 	Heimdallr
// 	
// 	Created by Hayden on 2021/1/14. 
//

#import "HMDStoreMemoryDB.h"
#import "NSDictionary+HMDSafe.h"
#import "pthread_extended.h"

static const NSUInteger kMaxRecordCountForEach = 400;

@interface HMDStoreMemoryDB () {
    pthread_mutex_t _memoryDBMutex;
}

@property (nonatomic, strong) NSMutableDictionary *databaseDic;

@end

@implementation HMDStoreMemoryDB

- (instancetype)init {
    if (self = [super init]) {
        _databaseDic = [NSMutableDictionary dictionary];
        pthread_mutex_init(&_memoryDBMutex, NULL);
    }
    
    return self;
}

- (BOOL)insertObjects:(NSArray<id> *)objects into:(NSString *)tableName appID:(NSString *)appID {
    if (!tableName || !appID) {
        return NO;
    }
    
    pthread_mutex_lock(&_memoryDBMutex);
    NSMutableArray *table = [self tableWithTableName:tableName appID:appID];
    if (!table) {
        table = [NSMutableArray new];
        NSString *key = [appID stringByAppendingString:tableName];
        [self.databaseDic hmd_setObject:table forKey:key];
    }
    
    BOOL overflow = table.count + objects.count > kMaxRecordCountForEach;
    if (overflow) {
        pthread_mutex_unlock(&_memoryDBMutex);
        return NO;
    }
    
    [table addObjectsFromArray:objects];
    pthread_mutex_unlock(&_memoryDBMutex);

    return YES;
}

- (NSArray<id> *)getAllObjectsWithTableName:(NSString *)tableName appID:(NSString *)appID {
    if (!tableName || !appID) {
        return nil;
    }
    
    pthread_mutex_lock(&_memoryDBMutex);
    NSMutableArray *table = [self tableWithTableName:tableName appID:appID];
    NSArray *result = nil;
    if (table && table.count) {
        result = table.copy;
    }
    pthread_mutex_unlock(&_memoryDBMutex);

    return result;
}

- (NSArray<id> *)getObjectsWithTableName:(NSString *)tableName appID:(NSString *)appID limit:(NSInteger)limitCount {
    if (!tableName || !appID || limitCount < 1) {
        return nil;
    }
    
    pthread_mutex_lock(&_memoryDBMutex);
    NSMutableArray *table = [self tableWithTableName:tableName appID:appID];
    NSArray *result = nil;
    if (table && table.count) {
        NSInteger length = limitCount > table.count ? table.count : limitCount;
        result = [table objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, length)]];
    }
    pthread_mutex_unlock(&_memoryDBMutex);
    
    return result;
}

- (void)deleteAllObjectsFromTable:(NSString *)tableName appID:(NSString *)appID {
    if (!tableName || !appID) {
        return;
    }
    
    pthread_mutex_lock(&_memoryDBMutex);
    NSMutableArray *table = [self tableWithTableName:tableName appID:appID];
    if (table && table.count) {
        [table removeAllObjects];
    }
    pthread_mutex_unlock(&_memoryDBMutex);
}

- (void)deleteObjectsFromTable:(NSString *)tableName appID:(NSString *)appID count:(NSInteger)count {
    if (!tableName || !appID || count < 1) {
        return;
    }
    
    pthread_mutex_lock(&_memoryDBMutex);
    NSMutableArray *table = [self tableWithTableName:tableName appID:appID];
    if (table && table.count >= count) {
        [table removeObjectsInRange:NSMakeRange(0, count)];
    }
    pthread_mutex_unlock(&_memoryDBMutex);
}

- (NSInteger)recordCountForTable:(NSString *)tableName appID:(NSString *)appID {
    if (!tableName || !appID) {
        return 0;
    }
    
    pthread_mutex_lock(&_memoryDBMutex);
    NSMutableArray *table = [self tableWithTableName:tableName appID:appID];
    NSInteger result = 0;
    if (table && table.count) {
        result = table.count;
    }
    pthread_mutex_unlock(&_memoryDBMutex);
    
    return result;
}

#pragma - mark Private

- (NSMutableArray *)tableWithTableName:(NSString *)tableName appID:(NSString *)appID {
    NSString *key = [appID stringByAppendingString:tableName];
    NSMutableArray *table = [self.databaseDic hmd_objectForKey:key class:NSMutableArray.class];
    return table;
}

@end
