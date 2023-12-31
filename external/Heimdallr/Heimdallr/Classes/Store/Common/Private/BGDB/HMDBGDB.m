//
//  BGDB.m
//  BGHMDDB
//
//  Created by biao on 2017/10/18.
//  Copyright © 2017年 Biao. All rights reserved.
//

#import "HMDBGDB.h"
#import "HMDBGTool.h"
#import "NSCache+HMDBGCache.h"
#import <mach/mach.h>
#import "HMDMacro.h"
#import "HMDALogProtocol.h"
#import "HMDDynamicCall.h"
#import "NSArray+HMDSafe.h"
#include "pthread_extended.h"

/**
 默认数据库名称
 */
#if !RANGERSAPM
#define SQLITE_NAME @"BGFMDB.db"
#else
#define SQLITE_NAME @"BGHMDDB.db"
#endif

#if !RANGERSAPM
#define HMDDatabaseQueue FMDatabaseQueue
#define HMDDatabase FMDatabase
#define HMDResultSet FMResultSet
#endif

#define MaxQueryPageNum 50
#define MAIN_THREAD_WAIT_MAX_TIME_INTERVAL 6

static const void * const BGHMDDBDispatchQueueSpecificKey = &BGHMDDBDispatchQueueSpecificKey;

@interface HMDBGDB()
/**
 数据库队列
 */
@property (nonatomic, strong) HMDDatabaseQueue *queue;
@property (nonatomic, strong) HMDDatabase* db;
@property (nonatomic, assign) BOOL inTransaction;
@property (nonatomic, assign) mach_port_t transactionThread;
@property (nonatomic, copy, readwrite) NSString *rootPath;
@property (nonatomic, assign) NSInteger delteErrorCode;
/**
 递归锁.
 */
//@property (nonatomic, strong) NSRecursiveLock *threadLock;
/**
 记录注册监听数据变化的block.
 */
@property (nonatomic,strong) NSMutableDictionary* changeBlocks;
/**
 存放当队列处于忙时的事务block
 */
@property (nonatomic,strong) NSMutableArray* transactionBlocks;

@end

static HMDBGDB* BGdb = nil;
@implementation HMDBGDB {
    pthread_mutex_t _mutex;
}

/*
 如存在降级无法兼容的DB升级，请递增版本号
 如遇版本降级会清空所有表，不能直接删除文件，避免数据库操作不在一个queue中导致异常
 */
+(uint32_t)currentDBUserVersion {
    return 1;
}

-(void)dealloc{
    //烧毁数据.
    [self destroy];
}


-(void)destroy{
    if (self.changeBlocks){
        [self.changeBlocks removeAllObjects];//清除所有注册列表.
        _changeBlocks = nil;
    }
    [self closeDB];
    if (BGdb) {
        BGdb = nil;
    }
    mutex_destroy(_mutex);

}
/**
 关闭数据库.
 */
-(void)closeDB{
    if(_disableCloseDB)return;//不关闭数据库
    
    mutex_lock(_mutex);
    @try {
        if(!_inTransaction && _queue) {//没有事务的情况下就关闭数据库.
            [_queue close];//关闭数据库.
            _queue = nil;
        }
    } @catch (NSException *exception) {

        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[BGDB closeDB] exception: %@", exception);
        NSAssert(true, @"[BGDB closeDB] exception: %@ This status is very important. Please contact Heimdallr developer ASAP.", exception);
        @throw;
    } @finally {
        mutex_unlock(_mutex);
    }
}

-(instancetype)init{
    self = [super init];
    if (self) {
        //创建递归锁.
        //self.threadLock = [[NSRecursiveLock alloc] init];
        //创建信号量.->互斥锁, 初始为1的信号量与互斥锁功能一致，并且互斥锁不会有优先级反转问题，并且死锁检测可以覆盖.
//        self.semaphore = dispatch_semaphore_create(1);
        mutex_init_normal(_mutex);
        
        self.delteErrorCode = 0;
    }
    return self;
}

-(NSMutableDictionary *)changeBlocks{
    if (_changeBlocks == nil) {
        @synchronized(self){
            if(_changeBlocks == nil){
            _changeBlocks = [NSMutableDictionary dictionary];
            }
        }
    }
    return _changeBlocks;
}

-(NSMutableArray *)transactionBlocks{
    if (_transactionBlocks == nil){
        @synchronized(self){
            if(_transactionBlocks == nil){
            _transactionBlocks = [NSMutableArray array];
            }
        }
    }
    return _transactionBlocks;
}

/**
 获取实例.
 */
- (instancetype)initWithPath:(NSString *)path {
    if(self = [super init]) {
        self.rootPath = path;
        mutex_init_normal(_mutex);
        HMDDatabaseQueue *tempQueue = [HMDDatabaseQueue databaseQueueWithPath:self.rootPath];
        if(tempQueue == nil) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"%@", @"Database open failed");
        }
        self.queue = tempQueue;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //数据库版本判断
            int curentVersion = [HMDBGDB currentDBUserVersion];
            [self.queue inDatabase:^(HMDDatabase * _Nonnull db) {
                int lastVersion = [db userVersion];
                if (lastVersion > curentVersion) {
                    // downgraded version
                    HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"version downgraded %d -> %d", lastVersion, curentVersion);
                    NSMutableArray *names = [NSMutableArray array];
                    HMDResultSet *rs = [db executeQuery:@"SELECT name FROM sqlite_master WHERE type='table'"];
                    if (rs != nil) {
                        while ([rs next]) {
                            //获取数据库名称
                            NSString *tablaName = [rs stringForColumn:@"name"];
                            //过滤内部表
                            if (![tablaName hasPrefix:@"sqlite_"]) {
                                [names addObject:tablaName];
                            }
                        }
                    }
                    //查询完后要关闭rs，不然会报@"Warning: there is at least one open result set around after performing
                    [rs close];
                    for (NSString *name in names) {
                        NSString* SQL = [NSString stringWithFormat:@"DROP TABLE IF EXISTS %@", name];
                        bool result = [db executeUpdate:SQL];
                        if (result) {
                            HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"drop table %@ success", name);
                        } else {
                            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"drop table %@ faild", name);
                        }
                    }
                    //尝试清理碎片
                    [db executeStatements:@"VACUUM"];
                    [db setUserVersion:curentVersion];
                } else if (lastVersion < curentVersion) {
                    // upgraded version
                    HMDALOG_PROTOCOL_DEBUG_TAG(@"Heimdallr", @"version upgraded %d -> %d", lastVersion, curentVersion);
                    [db setUserVersion:curentVersion];
                }
            }];
            
            //开启WAL模式
            [self.queue inDatabase:^(HMDDatabase *db) {
                [db stringForQuery:@"PRAGMA journal_mode=WAL;"];
            }];
        });
    }
    
    return self;
}

//事务操作
-(void)inTransaction:(BOOL (^_Nonnull)(void))block{
    NSAssert(block, @"block is nil!");
    NSAssert(![NSThread currentThread].isMainThread,@"Please do not call this interface on the main thread!");
    [self executeTransation:block];
}

/*
 执行事务操作
 */
-(void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) executeTransation:(BOOL (^_Nonnull)(void))block{
    mutex_lock(_mutex);
    @try {
        [self.queue inTransaction:^(HMDDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_DEPRECATED_DECLARATIONS
            self.inTransaction = db.inTransaction;
CLANG_DIAGNOSTIC_POP
            if (!self.inTransaction) {
                self.inTransaction = [db beginTransaction];
            }
            if (self.inTransaction) {
                thread_t thread_self = mach_thread_self();
                mach_port_deallocate(mach_task_self(), thread_self);
                self.transactionThread = thread_self;
                self.db = db;
                BOOL isCommit = block();
                if (self.inTransaction){
                    *rollback = !isCommit;
                    self.inTransaction = NO;
                }
                self.transactionThread = 0;
            }
        }];
    } @catch (NSException *exception) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[BGDB executeTransation:] exception: %@", exception);
        NSAssert(true, @"[BGDB closeDB] exception: %@ This status is very important. Please contact Heimdallr developer ASAP.", exception);
        @throw;
    } @finally {
        mutex_unlock(_mutex);
    }
}

- (void)executeCheckpoint {
    //only support HMDDBDatabase 2.7.4+
    if([self.queue respondsToSelector:NSSelectorFromString(@"checkpoint:error:")]) {
        mutex_lock(_mutex);
        @try {
            //3 means SQLITE_CHECKPOINT_TRUNCATE
            DC_OB(self.queue, checkpoint:error:, 3, NULL);
        }@catch (NSException *exception) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[BGDB executeCheckpoint:] exception: %@", exception);
            NSAssert(true, @"[BGDB executeCheckpoint] exception: %@ This status is very important. Please contact Heimdallr developer ASAP.", exception);
            @throw;
        } @finally {
            mutex_unlock(_mutex);
        }
    }
}

-(void)executeTransationBlocks{
   //[self.threadLock lock];
    @synchronized(self){
        if(_inTransaction || !_queue){
            if(self.transactionBlocks.count > 0) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2*NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self executeTransationBlocks];
                });
            }
            return;
        }

        while(self.transactionBlocks.count) {
            BOOL (^block)(void) = [self.transactionBlocks lastObject];
            [self executeTransation:block];
            [self.transactionBlocks removeLastObject];
        }
    }
    //[self.threadLock unlock];
}

/**
 为了对象层的事物操作而封装的函数.
 */
-(void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) executeDB:(void (^_Nonnull)(HMDDatabase *_Nonnull db))block{
    NSAssert(block, @"block is nil!");
    if (self.inTransaction) {
        thread_t thread_self = mach_thread_self();
        mach_port_deallocate(mach_task_self(), thread_self);
        if (thread_self == self.transactionThread) {
            block(self.db);
            return;
        }
    }
    if([NSThread isMainThread]) {
#ifdef DEBUG
        HMDPrint(
//          ------------------------------------------
                
            " [To business side]\n"
            " [This is not a BUG!] If you need to continue using,please comment out the block #ifdef DEBUG.\n"
            " [Feedback needed] Please screenshot the call stack of the currently suspended thread and feed it back to the Heimdallr developer\n"
            
            "[To Heimdallr developer]\n"
            " [Congratulations!] Recently, the problem that the main thread accesses the database is repaired. \n"
            " Whether it is caused by the business side or not, it needs to be strictly protected\n"
            " We made a deal! Whoever finds it needs to fix it ASAP! \n");
        
//          ------------------------------------------
        __builtin_trap();
#endif
        if(mutex_trylock(_mutex)) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[BGDB excecuteDB:] on mainThread exceed");
            return; // DROP THIS TIME DB QUERY
        }
    }
    else mutex_lock(_mutex);
    
    @try {
        [self.queue inDatabase:^(HMDDatabase *db){
            self.db = db;
            block(db);
        }];
    } @catch (NSException *exception) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[BGDB executeDB:] exception: %@", exception);
        NSAssert(true, @"[BGDB closeDB] exception: %@ This status is very important. please inform Heimdallr developers ASAP!", exception);
        @throw;
    } @finally {
        mutex_unlock(_mutex);
    }
}

/**
 注册数据变化监听.
 */
-(BOOL)registerChangeWithName:(NSString* const _Nonnull)name block:(hmdbg_changeBlock)block{
    if ([self.changeBlocks.allKeys containsObject:name]){
        HMDLog(@"%@", ([NSString stringWithFormat:@"Repeatedly register monitoring %@ table, and registration failed!",name]));
        return NO;
    }else{
        [self.changeBlocks setObject:block forKey:name];
        return YES;
    }
}
/**
 移除数据变化监听.
 */
-(BOOL)removeChangeWithName:(NSString* const _Nonnull)name{
    if ([self.changeBlocks.allKeys containsObject:name]){
        [self.changeBlocks removeObjectForKey:name];
        return YES;
    }else{
        HMDLog(@"%@", ([NSString stringWithFormat:@"Table %@ has not registered monitor, so removing monitor failed!",name]));
        return NO;
    }
}
-(void)doChangeWithName:(NSString* const _Nonnull)name flag:(BOOL)flag state:(bg_changeState)state{
    if(flag && self.changeBlocks.count>0){
        //开一个子线程去执行block,防止死锁.
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            [self.changeBlocks enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop){
                NSString* tablename = [key componentsSeparatedByString:@"*"].firstObject;
                if([name isEqualToString:tablename]){
                    void(^block)(bg_changeState) = obj;
                    //返回主线程回调.
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        block(state);
                    });
                }
            }];
        });
    }
}

/**
 数据库中是否存在表.
 */
-(void)isExistWithTableName:(NSString* _Nonnull)name complete:(hmdbg_complete_B)complete{
    NSAssert(name,@"The name of the table cannot be nil!");
    __block BOOL result = NO;
    [self executeDB:^(HMDDatabase * _Nonnull db) {
        result = [db tableExists:name];
    }];
    complete(result);
}
/**
 对用户暴露的
 */
-(BOOL)bg_isExistWithTableName:( NSString* _Nonnull)name{
    NSAssert(name,@"The name of the table cannot be nil!");
    __block BOOL result = NO;
    [self executeDB:^(HMDDatabase * _Nonnull db) {
        result = [db tableExists:name];
    }];
    return result;
}

/**
 创建表(如果存在则不创建).
 */
-(void)__attribute__((annotate("oclint:suppress[block captured instance self]")))
 createTableWithTableName:(NSString* _Nonnull)name keys:(NSArray<NSString*>* _Nonnull)keys unionPrimaryKeys:(NSArray* _Nullable)unionPrimaryKeys uniqueKeys:(NSArray* _Nullable)uniqueKeys complete:(hmdbg_complete_B)complete{
    NSAssert(name,@"The name of the table cannot be nil!");
    NSAssert(keys,@"NSArray named keys cannot be nil!");
    //创表
    __block BOOL result = NO;
    [self executeDB:^(HMDDatabase * _Nonnull db) {
        NSString* header = [NSString stringWithFormat:@"create table if not exists %@ (",name];
        NSMutableString* sql = [[NSMutableString alloc] init];
        [sql appendString:header];
        NSInteger uniqueKeyFlag = uniqueKeys.count;
        NSMutableArray* tempUniqueKeys = [NSMutableArray arrayWithArray:uniqueKeys];
        for(int i=0;i<keys.count;i++){
            NSString* key = [keys[i] componentsSeparatedByString:@"*"][0];
            
            if(tempUniqueKeys.count && [tempUniqueKeys containsObject:key]){
                for(NSString* uniqueKey in tempUniqueKeys){
                    if([HMDBGTool isUniqueKey:uniqueKey with:keys[i]]){
                        [sql appendFormat:@"%@ unique",[HMDBGTool keyAndType:keys[i]]];
                        [tempUniqueKeys removeObject:uniqueKey];
                        uniqueKeyFlag--;
                        break;
                    }
                }
            }else{
                if ([key isEqualToString:hmdbg_primaryKey] && !unionPrimaryKeys.count){
                    [sql appendFormat:@"%@ primary key autoincrement",[HMDBGTool keyAndType:keys[i]]];
                }else{
                    [sql appendString:[HMDBGTool keyAndType:keys[i]]];
                }
            }
            
            if (i == (keys.count-1)) {
                if(unionPrimaryKeys.count){
                    [sql appendString:@",primary key ("];
                    [unionPrimaryKeys enumerateObjectsUsingBlock:^(id  _Nonnull unionKey, NSUInteger idx, BOOL * _Nonnull stop) {
                        if(idx == 0){
                            [sql appendString:hmdbg_sqlKey(unionKey)];
                        }else{
                            [sql appendFormat:@",%@",hmdbg_sqlKey(unionKey)];
                        }
                    }];
                    [sql appendString:@")"];
                }
                [sql appendString:@");"];
            }else{
                [sql appendString:@","];
            }
            
        }//for over
            
        if(uniqueKeys.count){
            NSAssert(!uniqueKeyFlag,@"'Unique constraint' not found! Please check whether the return value of bg_uniqueKeys function in model class .m file is correct!");
        }
        
        result = [db executeUpdate:sql];
    }];
    
    hmdbg_completeBlock(result);
}
-(NSInteger)getKeyMaxForTable:(NSString*)name key:(NSString*)key db:(HMDDatabase*)db{
    __block NSInteger num = 0;
    [db executeStatements:[NSString stringWithFormat:@"select max(%@) from %@",key,name] withResultBlock:^int(NSDictionary *resultsDictionary){
        id dbResult = [resultsDictionary.allValues lastObject];
        if(dbResult && ![dbResult isKindOfClass:[NSNull class]]) {
            num = [dbResult integerValue];
        }
        return 0;
    }];
    return num;
}
/**
 插入数据.
 */
-(void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) insertIntoTableName:(NSString* _Nonnull)name Dict:(NSDictionary* _Nonnull)dict complete:(hmdbg_complete_B)complete{
    NSAssert(name,@"The name of the table cannot be nil!");
    NSAssert(dict,@"NSDictionary containing inserted values cannot be nil!");
    __block BOOL result = NO;
    [self executeDB:^(HMDDatabase * _Nonnull db) {
        NSArray* keys = dict.allKeys;
        if([keys containsObject:hmdbg_sqlKey(hmdbg_primaryKey)]){
           NSInteger num = [self getKeyMaxForTable:name key:hmdbg_sqlKey(hmdbg_primaryKey) db:db];
           [dict setValue:@(num+1) forKey:hmdbg_sqlKey(hmdbg_primaryKey)];
        }
        NSArray* values = dict.allValues;
        NSMutableString* SQL = [[NSMutableString alloc] init];
        [SQL appendFormat:@"insert into %@(",name];
        for(int i=0;i<keys.count;i++){
            [SQL appendFormat:@"%@",keys[i]];
            if(i == (keys.count-1)){
                [SQL appendString:@") "];
            }else{
                [SQL appendString:@","];
            }
        }
        [SQL appendString:@"values("];
        for(int i=0;i<values.count;i++){
            [SQL appendString:@"?"];
            if(i == (keys.count-1)){
                [SQL appendString:@");"];
            }else{
                [SQL appendString:@","];
            }
        }
        
        result = [db executeUpdate:SQL withArgumentsInArray:values];
    }];
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:bg_insert];
    hmdbg_completeBlock(result);
}
/**
 批量插入
 */
-(void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) insertIntoTableName:(NSString* _Nonnull)name DictArray:(NSArray<NSDictionary*>* _Nonnull)dictArray complete:(hmdbg_complete_B)complete{
    NSAssert(name,@"The name of the table cannot be nil!");
    __block BOOL result = NO;
    [self executeDB:^(HMDDatabase * _Nonnull db) {
        [db beginTransaction];
        __block NSInteger counter = 0;
        [dictArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
            @autoreleasepool {
                NSArray* keys = dict.allKeys;
                NSArray* values = dict.allValues;
                NSMutableString* SQL = [[NSMutableString alloc] init];
                [SQL appendFormat:@"insert into %@(",name];
                for(int i=0;i<keys.count;i++){
                    [SQL appendFormat:@"%@",keys[i]];
                    if(i == (keys.count-1)){
                        [SQL appendString:@") "];
                    }else{
                        [SQL appendString:@","];
                    }
                }
                [SQL appendString:@"values("];
                for(int i=0;i<values.count;i++){
                    [SQL appendString:@"?"];
                    if(i == (keys.count-1)){
                        [SQL appendString:@");"];
                    }else{
                        [SQL appendString:@","];
                    }
                }
                NSError *error = nil;
                BOOL flag = [db executeUpdate:SQL values:values error:&error];
                if(flag){
                    counter++;
                }else{
                    *stop=YES;
                }
            }
        }];
        
        if(dictArray.count == counter){
            result = YES;
            [db commit];
        }else{
            result = NO;
            [db rollback];
        }
        
    }];
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:bg_insert];
    hmdbg_completeBlock(result);
}
/**
 批量更新
 over
 */
-(void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) updateSetTableName:(NSString* _Nonnull)name class:(__unsafe_unretained _Nonnull Class)cla DictArray:(NSArray<NSDictionary*>* _Nonnull)dictArray complete:(hmdbg_complete_B)complete{
    __block BOOL result = NO;
    [self executeDB:^(HMDDatabase * _Nonnull db) {
        [db beginTransaction];
        __block NSInteger counter = 0;
        [dictArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
            @autoreleasepool {
                NSArray* uniqueKeys = [HMDBGTool executeSelector:hmdbg_uniqueKeysSelector forClass:cla];
                NSMutableDictionary* tempDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
                NSMutableString* where = [NSMutableString new];
                if(uniqueKeys.count > 1){
                    [where appendString:@" where"];
                    [uniqueKeys enumerateObjectsUsingBlock:^(NSString*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop){
                        NSString* uniqueKey = hmdbg_sqlKey(obj);
                        id uniqueKeyVlaue = tempDict[uniqueKey];
                        if(idx < (uniqueKeys.count-1)){
                            [where appendFormat:@" %@=%@ or",uniqueKey,hmdbg_sqlValue(uniqueKeyVlaue)];
                        }else{
                            [where appendFormat:@" %@=%@",uniqueKey,hmdbg_sqlValue(uniqueKeyVlaue)];
                        }
                        [tempDict removeObjectForKey:uniqueKey];
                    }];
                }else if(uniqueKeys.count == 1){
                    NSString* uniqueKey = hmdbg_sqlKey([uniqueKeys firstObject]);
                    id uniqueKeyVlaue = tempDict[uniqueKey];
                    [where appendFormat:@" where %@=%@",uniqueKey,hmdbg_sqlValue(uniqueKeyVlaue)];
                    [tempDict removeObjectForKey:uniqueKey];
                }else if([dict.allKeys containsObject:hmdbg_sqlKey(hmdbg_primaryKey)]){
                    NSString* primaryKey = hmdbg_sqlKey(hmdbg_primaryKey);
                    id primaryKeyVlaue = tempDict[primaryKey];
                    [where appendFormat:@" where %@=%@",primaryKey,hmdbg_sqlValue(primaryKeyVlaue)];
                    [tempDict removeObjectForKey:primaryKey];
                }else;
                
                NSMutableArray* arguments = [NSMutableArray array];
                NSMutableString* SQL = [[NSMutableString alloc] init];
                [SQL appendFormat:@"update %@ set ",name];
                [tempDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    [SQL appendFormat:@"%@=?,",key];
                    [arguments addObject:obj];
                }];
                SQL = [NSMutableString stringWithString:[SQL substringToIndex:SQL.length-1]];
                if(where.length) {
                    [SQL appendString:where];
                }
                BOOL flag = [db executeUpdate:SQL withArgumentsInArray:arguments];
                if(flag){
                    counter++;
                }
            }
        }];
        
        if (dictArray.count == counter){
            result = YES;
            [db commit];
        }else{
            result = NO;
            [db rollback];
        }
        
    }];
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:bg_update];
    hmdbg_completeBlock(result);
}

/**
 批量插入或更新.
 */
-(void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) bg_saveOrUpdateWithTableName:(NSString* _Nonnull)tablename class:(__unsafe_unretained _Nonnull Class)cla DictArray:(NSArray<NSDictionary*>* _Nonnull)dictArray complete:(hmdbg_complete_B)complete{
    __block BOOL result = NO;
    [self executeDB:^(HMDDatabase * _Nonnull db) {
        [db beginTransaction];
        __block NSInteger counter = 0;
        [dictArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
            @autoreleasepool {
                NSString* bg_id = hmdbg_sqlKey(hmdbg_primaryKey);
                //获得"唯一约束"
                NSArray* uniqueKeys = [HMDBGTool executeSelector:hmdbg_uniqueKeysSelector forClass:cla];
                //获得"联合主键"
                NSArray* unionPrimaryKeys =[HMDBGTool executeSelector:hmdbg_unionPrimaryKeysSelector forClass:cla];
                NSMutableDictionary* tempDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
                NSMutableString* where = [NSMutableString new];
                BOOL isSave = NO;//是否存储还是更新.
                if(uniqueKeys.count || unionPrimaryKeys.count){
                    NSArray* tempKeys;
                    NSString* orAnd;
                    
                    if(unionPrimaryKeys.count){
                        tempKeys = unionPrimaryKeys;
                        orAnd = @"and";
                    }else{
                        tempKeys = uniqueKeys;
                        orAnd = @"or";
                    }
                    
                    if(tempKeys.count == 1){
                        NSString* tempkey = hmdbg_sqlKey([tempKeys firstObject]);
                        id tempkeyVlaue = tempDict[tempkey];
                        [where appendFormat:@" where %@=%@",tempkey,hmdbg_sqlValue(tempkeyVlaue)];
                    }else{
                        [where appendString:@" where"];
                        [tempKeys enumerateObjectsUsingBlock:^(NSString*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop){
                            NSString* tempkey = hmdbg_sqlKey(obj);
                            id tempkeyVlaue = tempDict[tempkey];
                            if(idx < (tempKeys.count-1)){
                                [where appendFormat:@" %@=%@ %@",tempkey,hmdbg_sqlValue(tempkeyVlaue),orAnd];
                            }else{
                                [where appendFormat:@" %@=%@",tempkey,hmdbg_sqlValue(tempkeyVlaue)];
                            }
                        }];
                    }
                    NSString* dataCountSql = [NSString stringWithFormat:@"select count(*) from %@%@",tablename,where];
                    __block NSInteger dataCount = 0;
                    [db executeStatements:dataCountSql withResultBlock:^int(NSDictionary *resultsDictionary) {
                        dataCount = [[resultsDictionary.allValues lastObject] integerValue];
                        return 0;
                    }];
                    if(dataCount){
                        //更新操作
                        [tempKeys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            [tempDict removeObjectForKey:hmdbg_sqlKey(obj)];
                        }];
                    }else{
                        //插入操作
                        isSave = YES;
                    }
                }else{
                    if([tempDict.allKeys containsObject:bg_id]){
                        //更新操作
                        id primaryKeyVlaue = tempDict[bg_id];
                        [where appendFormat:@" where %@=%@",bg_id,hmdbg_sqlValue(primaryKeyVlaue)];
                    }else{
                        //插入操作
                        isSave = YES;
                    }
                }
                
                NSMutableString* SQL = [[NSMutableString alloc] init];
                NSMutableArray* arguments = [NSMutableArray array];
                if(isSave){//存储操作
                    NSInteger num = [self getKeyMaxForTable:tablename key:bg_id db:db];
                    [tempDict setValue:@(num+1) forKey:bg_id];
                    [SQL appendFormat:@"insert into %@(",tablename];
                    NSArray* keys = tempDict.allKeys;
                    NSArray* values = tempDict.allValues;
                    for(int i=0;i<keys.count;i++){
                        [SQL appendFormat:@"%@",keys[i]];
                        if(i == (keys.count-1)){
                            [SQL appendString:@") "];
                        }else{
                            [SQL appendString:@","];
                        }
                    }
                    [SQL appendString:@"values("];
                    for(int i=0;i<values.count;i++){
                        [SQL appendString:@"?"];
                        if(i == (keys.count-1)){
                            [SQL appendString:@");"];
                        }else{
                            [SQL appendString:@","];
                        }
                        [arguments addObject:values[i]];
                    }
                }else{//更新操作
                    if([tempDict.allKeys containsObject:bg_id]){
                        [tempDict removeObjectForKey:bg_id];//移除主键
                    }
                    [SQL appendFormat:@"update %@ set ",tablename];
                    [tempDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                        [SQL appendFormat:@"%@=?,",key];
                        [arguments addObject:obj];
                    }];
                    SQL = [NSMutableString stringWithString:[SQL substringToIndex:SQL.length-1]];
                    if(where.length) {
                        [SQL appendString:where];
                    }
                }
                
                BOOL flag = [db executeUpdate:SQL withArgumentsInArray:arguments];
                if(flag){
                    counter++;
                }
            }
        }];
        
        if (dictArray.count == counter){
            result = YES;
            [db commit];
        }else{
            result = NO;
            [db rollback];
        }
        
    }];
    //数据监听执行函数
    [self doChangeWithName:tablename flag:result state:bg_update];
    hmdbg_completeBlock(result);
}

-(void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) queryQueueWithTableName:(NSString* _Nonnull)name conditions:(NSString* _Nullable)conditions complete:(hmdbg_complete_A)complete{
    NSAssert(name,@"The name of the table cannot be nil!");
    __block NSMutableArray* arrM = nil;
    [self executeDB:^(HMDDatabase * _Nonnull db){
        NSString* SQL = conditions?[NSString stringWithFormat:@"select * from %@ %@",name,conditions]:[NSString stringWithFormat:@"select * from %@",name];
        // 1.查询数据
        HMDResultSet *rs = [db executeQuery:SQL];
        if (rs == nil) {
            HMDLog(@"QUERY ERROR. Probably because the name of class variable changed, or 'field'/'table' doesn't exist. Please read after data stored!");
        }else{
            arrM = [[NSMutableArray alloc] init];
        }
        // 2.遍历结果集
        while (rs.next) {
            NSMutableDictionary* dictM = [[NSMutableDictionary alloc] init];
            NSUInteger keysCount = [[[rs columnNameToIndexMap] allKeys] count];
            for (int i=0;i<keysCount;i++) {
                dictM[[rs columnNameForIndex:i]] = [rs objectForColumnIndex:i];
            }
            [arrM addObject:dictM];
        }
        //查询完后要关闭rs，不然会报@"Warning: there is at least one open result set around after performing
        [rs close];
    }];
    
    hmdbg_completeBlock(arrM);
}

/**
 直接传入条件sql语句查询
 */
-(void)queryWithTableName:(NSString* _Nonnull)name conditions:(NSString* _Nullable)conditions complete:(hmdbg_complete_A)complete{
    @autoreleasepool {
        [self queryQueueWithTableName:name conditions:conditions complete:complete];
    }
}
/**
 根据条件查询字段.
 */
-(void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) queryWithTableName:(NSString* _Nonnull)name keys:(NSArray<NSString*>* _Nullable)keys where:(NSArray* _Nullable)where complete:(hmdbg_complete_A)complete{
    NSAssert(name,@"The name of the table cannot be nil");
    NSMutableArray* arrM = [[NSMutableArray alloc] init];
    __block NSArray* arguments;
    [self executeDB:^(HMDDatabase * _Nonnull db) {
        NSMutableString* SQL = [[NSMutableString alloc] init];
        [SQL appendString:@"select"];
        if ((keys!=nil)&&(keys.count>0)) {
            [SQL appendString:@" "];
            for(int i=0;i<keys.count;i++){
                [SQL appendFormat:@"%@",keys[i]];
                if (i != (keys.count-1)) {
                    [SQL appendString:@","];
                }
            }
        }else{
            [SQL appendString:@" *"];
        }
        [SQL appendFormat:@" from %@",name];
        
        if(where && (where.count>0)){
            NSArray* results = [HMDBGTool where:where];
            [SQL appendString:results[0]];
            arguments = results[1];
        }
        
        // 1.查询数据
        HMDResultSet *rs = [db executeQuery:SQL withArgumentsInArray:arguments];
        if (rs == nil) {
            HMDLog(@"QUERY ERROR. Probably because the name of class variable changed, or 'field'/'table' doesn't exist. Please read after data stored, or check whether 'filed name' in conditional array is correct!");
        }
        // 2.遍历结果集
        while (rs.next) {
            NSMutableDictionary* dictM = [[NSMutableDictionary alloc] init];
            NSUInteger keyCount = [[[rs columnNameToIndexMap] allKeys] count];
            for (int i=0;i<keyCount;i++) {
                dictM[[rs columnNameForIndex:i]] = [rs objectForColumnIndex:i];
            }
            [arrM addObject:dictM];
        }
        //查询完后要关闭rs，不然会报@"Warning: there is at least one open result set around after performing
        [rs close];
    }];
    
    hmdbg_completeBlock(arrM);
}

/**
 查询对象.
 */
-(void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) queryWithTableName:(NSString* _Nonnull)name where:(NSString* _Nullable)where complete:(hmdbg_complete_A)complete{
    NSAssert(name,@"The name of the table cannot be nil!");
    NSMutableArray* arrM = [[NSMutableArray alloc] init];
    [self executeDB:^(HMDDatabase * _Nonnull db) {
        NSMutableString* SQL = [NSMutableString string];
        [SQL appendFormat:@"select * from %@",name];
        !where?:[SQL appendFormat:@" %@",where];
        // 1.查询数据
        HMDResultSet *rs = [db executeQuery:SQL];
        if (rs == nil) {
            HMDLog(@"QUERY ERROR! QUERY ERROR! Table doesn't exist! Please read data after data stored!");
        }
        // 2.遍历结果集
        while (rs.next) {
            NSMutableDictionary* dictM = [[NSMutableDictionary alloc] init];
            NSUInteger keyCount = [[[rs columnNameToIndexMap] allKeys] count];
            for (int i=0;i<keyCount;i++) {
                dictM[[rs columnNameForIndex:i]] = [rs objectForColumnIndex:i];
            }
            [arrM addObject:dictM];
        }
        //查询完后要关闭rs，不然会报@"Warning: there is at least one open result set around after performing
        [rs close];
    }];
    
    hmdbg_completeBlock(arrM);
}

/**
 更新数据.
 */
-(void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) updateWithTableName:(NSString* _Nonnull)name valueDict:(NSDictionary* _Nonnull)valueDict where:(NSArray* _Nullable)where complete:(hmdbg_complete_B)complete{
    NSAssert(name,@"The name of the table cannot be nil!");
    NSAssert(valueDict,@"The NSDictionary of updating data cannot be nil!");
    __block BOOL result = NO;
    NSMutableArray* arguments = [NSMutableArray array];
    [self executeDB:^(HMDDatabase * _Nonnull db) {
        NSMutableString* SQL = [[NSMutableString alloc] init];
        [SQL appendFormat:@"update %@ set ",name];
        for(int i=0;i<valueDict.allKeys.count;i++){
            [SQL appendFormat:@"%@=?",valueDict.allKeys[i]];
            [arguments addObject:valueDict[valueDict.allKeys[i]]];
            if (i != (valueDict.allKeys.count-1)) {
                [SQL appendString:@","];
            }
        }
        
        if(where && (where.count>0)){
            NSArray* results = [HMDBGTool where:where];
            [SQL appendString:results[0]];
            [arguments addObjectsFromArray:results[1]];
        }
        
        result = [db executeUpdate:SQL withArgumentsInArray:arguments];
    }];
    
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:bg_update];
    hmdbg_completeBlock(result);
}
-(void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) updateQueueWithTableName:(NSString* _Nonnull)name valueDict:(NSDictionary* _Nullable)valueDict conditions:(NSString* _Nonnull)conditions complete:(hmdbg_complete_B)complete{
    NSAssert(name,@"The name of the table cannot be nil!");
    __block BOOL result = NO;
    [self executeDB:^(HMDDatabase * _Nonnull db){
        NSString* SQL;
        if (!valueDict || !valueDict.count) {
            SQL = [NSString stringWithFormat:@"update %@ %@",name,conditions];
        }else{
            NSMutableString* param = [NSMutableString stringWithFormat:@"update %@ set ",name];
            for(int i=0;i<valueDict.allKeys.count;i++){
                NSString* key = valueDict.allKeys[i];
                [param appendFormat:@"%@=?",key];
                if(i != (valueDict.allKeys.count-1)) {
                    [param appendString:@","];
                }
            }
            [param appendFormat:@" %@",conditions];
            SQL = param;
        }
        result = [db executeUpdate:SQL withArgumentsInArray:valueDict.allValues];
    }];
    
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:bg_update];
    hmdbg_completeBlock(result);
}
/**
 直接传入条件sql语句更新.
 */
-(void)updateWithObject:(id _Nonnull)object valueDict:(NSDictionary* _Nullable)valueDict conditions:(NSString* _Nonnull)conditions complete:(hmdbg_complete_B)complete{
    @autoreleasepool {
        //自动判断是否有字段改变,自动刷新数据库.
        [self ifIvarChangeForObject:object ignoredKeys:[HMDBGTool executeSelector:hmdbg_ignoreKeysSelector forClass:[object class]]];
        NSString* tablename = [HMDBGTool getTableNameWithObject:object];
        [self updateQueueWithTableName:tablename valueDict:valueDict conditions:conditions complete:complete];
    }
}
/**
 直接传入条件sql语句更新对象.
 */
-(void)updateObject:(id _Nonnull)object ignoreKeys:(NSArray* const _Nullable)ignoreKeys conditions:(NSString* _Nonnull)conditions complete:(hmdbg_complete_B)complete{
    @autoreleasepool {
        NSString* tableName = [HMDBGTool getTableNameWithObject:object];
        [self ifNotExistWillCreateTableWithObject:object ignoredKeys:ignoreKeys];
        //自动判断是否有字段改变,自动刷新数据库.
        [self ifIvarChangeForObject:object ignoredKeys:ignoreKeys];
        NSDictionary* valueDict = [HMDBGTool getDictWithObject:object ignoredKeys:ignoreKeys filtModelInfoType:bg_ModelInfoSingleUpdate];
        [self updateQueueWithTableName:tableName valueDict:valueDict conditions:conditions complete:complete];
    }
}

-(void)updateObject:(id _Nonnull)object checkIvarChanged:(BOOL)checkIvarChanged propertyName:(NSString * _Nonnull)propertyName propertyValue:(id _Nonnull)propertyValue conditions:(NSString* _Nonnull)conditions complete:(hmdbg_complete_B)complete {
    if (checkIvarChanged) {
        NSArray *ignoredKeys = [HMDBGTool executeSelector:hmdbg_ignoreKeysSelector forClass:[object class]];
        [self ifIvarChangeForObject:object ignoredKeys:ignoredKeys];
    }
    
    [self updateObject:object propertyName:propertyName propertyValue:propertyValue conditions:conditions complete:complete];
}

-(void)updateObject:(id _Nonnull)object propertyName:(NSString * _Nonnull)propertyName propertyValue:(id)propertyValue conditions:(NSString* _Nonnull)conditions complete:(hmdbg_complete_B)complete {
    if (!propertyName || !propertyValue) {
        if (complete) {
            complete(NO);
        }
        return;
    }
        
    @autoreleasepool {
        NSString *tableName = [HMDBGTool getTableNameWithObject:object];
        NSString *ivarName = [@"_" stringByAppendingString:propertyName];
        NSString *propertyType = [HMDBGTool getIvarEncoding:ivarName class:[object class]];
        
        NSAssert(propertyType != NULL,
                 @"[FATAL ERROR] Please preserve current application environment, and contact Heimdallr developer ASAP");
        if(propertyType == NULL) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr",
                                      @"+ [BGDB updateObject:%@ "
                                              "propertyName:%@ "
                                              "propertyValue:%@ "
                                              "conditions:%@ "
                                              "complete:%@] "
                                              "ERROR: encode type null (CRASH) "
                                              "tableName %@ ivarName %@ propertyType %@",
                                      object, propertyName, propertyValue, conditions, complete, tableName, ivarName, propertyType);
            if(complete) complete(NO);
            return;
        }
        
        id sqlValue = [HMDBGTool getSqlValue:propertyValue type:propertyType encode:YES];
        if (!sqlValue) {
            if (complete) {
                complete(NO);
            }
            return;
        }
        NSDictionary* valueDict = [NSDictionary dictionaryWithObject:sqlValue forKey:propertyName];
        [self updateQueueWithTableName:tableName valueDict:valueDict conditions:conditions complete:complete];
    }
}

-(void)updateQueueWithTableName:(NSString* _Nonnull)name conditions:(NSString* _Nonnull)conditions complete:(hmdbg_complete_B)complete {
    NSAssert(name && conditions,@"name != nil && condtions != nil");
    __block BOOL result = NO;
    [self executeDB:^(HMDDatabase * _Nonnull db){
        NSString* SQL;
        if (conditions) {
            SQL = [NSString stringWithFormat:@"update %@ %@",name,conditions];
            result = [db executeUpdate:SQL];
        }
    }];
    hmdbg_completeBlock(result);
    
}

/**
 根据keypath更新数据
 */
-(void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) updateWithTableName:(NSString* _Nonnull)name forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues valueDict:(NSDictionary* _Nonnull)valueDict complete:(hmdbg_complete_B)complete{
    NSString* like = [HMDBGTool getLikeWithKeyPathAndValues:keyPathValues where:YES];
    NSMutableArray* arguments = [NSMutableArray array];
    __block BOOL result = NO;
    [self executeDB:^(HMDDatabase * _Nonnull db){
        NSMutableString* SQL = [[NSMutableString alloc] init];
        [SQL appendFormat:@"update %@ set ",name];
        for(int i=0;i<valueDict.allKeys.count;i++){
            [SQL appendFormat:@"%@=?",valueDict.allKeys[i]];
            [arguments addObject:valueDict[valueDict.allKeys[i]]];
            if (i != (valueDict.allKeys.count-1)) {
                [SQL appendString:@","];
            }
        }
        [SQL appendString:like];
        result = [db executeUpdate:SQL withArgumentsInArray:arguments];
    }];
    
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:bg_update];
    hmdbg_completeBlock(result);
}
/**
 根据条件删除数据.
 */
-(void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) deleteWithTableName:(NSString* _Nonnull)name where:(NSArray* _Nonnull)where complete:(hmdbg_complete_B)complete{
    NSAssert(name,@"The name of the table cannot be nil!");
    NSAssert(where,@"The conditional arrray called where cannot be nil!");
    __block BOOL result = NO;
    NSMutableArray* arguments = [NSMutableArray array];
    [self executeDB:^(HMDDatabase * _Nonnull db) {
        NSMutableString* SQL = [[NSMutableString alloc] init];
        [SQL appendFormat:@"delete from %@",name];
        
        if(where && (where.count>0)){
            NSArray* results = [HMDBGTool where:where];
            [SQL appendString:results[0]];
            [arguments addObjectsFromArray:results[1]];
        }
        
        result = [db executeUpdate:SQL withArgumentsInArray:arguments];
    }];
    
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:bg_delete];
    hmdbg_completeBlock(result);
}

-(void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) deleteQueueWithTableName:(NSString* _Nonnull)name conditions:(NSString* _Nullable)conditions complete:(hmdbg_complete_B)complete{
    NSAssert(name,@"The name of the table cannot be nil!");
    __block BOOL result = NO;
    [self executeDB:^(HMDDatabase * _Nonnull db) {
        NSString* SQL = conditions?[NSString stringWithFormat:@"delete from %@ %@",name,conditions]:[NSString stringWithFormat:@"delete from %@",name];
        NSError *error = nil;
        result = [db executeUpdate:SQL withErrorAndBindings:&error];
        if (!result) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[BGDB deleteQueueWithTableName:conditions:complete:] error !!!! sql = %@, error = %@", SQL, error);
            self->_delteErrorCode = error.code;
        }
    }];
    
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:bg_delete];
    hmdbg_completeBlock(result);
}

/**
 直接传入条件sql语句删除.
 */
-(void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) deleteWithTableName:(NSString* _Nonnull)name conditions:(NSString* _Nullable)conditions complete:(hmdbg_complete_B)complete{
    [self deleteQueueWithTableName:name conditions:conditions complete:complete];
}

-(void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) deleteQueueWithTableName:(NSString* _Nonnull)name forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(hmdbg_complete_B)complete{
    NSAssert(name,@"The name of the table cannot be nil!");
    NSString* like = [HMDBGTool getLikeWithKeyPathAndValues:keyPathValues where:YES];
    __block BOOL result = NO;
    [self executeDB:^(HMDDatabase * _Nonnull db) {
        NSMutableString* SQL = [[NSMutableString alloc] init];
        [SQL appendFormat:@"delete from %@%@",name,like];
        NSError *error = nil;
        result = [db executeUpdate:SQL withErrorAndBindings:&error];
        if (!result) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[BGDB deleteQueueWithTableName:forKeyPathAndValues:complete:] error !!!! sql = %@, error = %@", SQL, error);
        }
    }];
    
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:bg_delete];
    hmdbg_completeBlock(result);
}

//根据keypath删除表内容.
-(void)deleteWithTableName:(NSString* _Nonnull)name forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(hmdbg_complete_B)complete{
    [self deleteQueueWithTableName:name forKeyPathAndValues:keyPathValues complete:complete];
}
/**
 根据表名删除表格全部内容.
 */
-(void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) clearTable:(NSString* _Nonnull)name complete:(hmdbg_complete_B)complete{
    NSAssert(name,@"The name of the table cannot be nil!");
    __block BOOL result = NO;
    [self executeDB:^(HMDDatabase * _Nonnull db) {
        NSString* SQL = [NSString stringWithFormat:@"delete from %@",name];
        result = [db executeUpdate:SQL];
    }];
    
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:bg_delete];
    hmdbg_completeBlock(result);
}

/**
 删除表.
 */
-(void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) dropTable:(NSString* _Nonnull)name complete:(hmdbg_complete_B)complete{
    NSAssert(name,@"The name of the table cannot be nil!");
    __block BOOL result = NO;
    [self executeDB:^(HMDDatabase * _Nonnull db) {
        NSString* SQL = [NSString stringWithFormat:@"drop table %@",name];
        result = [db executeUpdate:SQL];
    }];
    
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:bg_drop];
    hmdbg_completeBlock(result);
}

/**
 删除表(线程安全).
 */
-(void)dropSafeTable:(NSString* _Nonnull)name complete:(hmdbg_complete_B)complete{
    @autoreleasepool {
        [self dropTable:name complete:complete];
    }
}
/**
 动态添加表字段.
 */
-(void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) addTable:(NSString* _Nonnull)name key:(NSString* _Nonnull)key complete:(hmdbg_complete_B)complete{
    NSAssert(name,@"The name of the table cannot be nil!");
    __block BOOL result = NO;
    [self executeDB:^(HMDDatabase * _Nonnull db) {
        NSString* SQL = [NSString stringWithFormat:@"alter table %@ add %@;",name,[HMDBGTool keyAndType:key]];
        result = [db executeUpdate:SQL];
    }];
    hmdbg_completeBlock(result);
}
/**
 查询该表中有多少条数据
 */
-(long long)__attribute__((annotate("oclint:suppress[block captured instance self]"))) countQueueForTable:(NSString* _Nonnull)name where:(NSArray* _Nullable)where{
    NSAssert(name,@"The name of the table cannot be nil!");
    NSAssert(!(where.count%3),@"The condition array named 'where' is wrong!");
    NSMutableString* strM = [NSMutableString string];
    !where?:[strM appendString:@" where "];
    for(int i=0;i<where.count;i+=3){
        if ([where[i+2] isKindOfClass:[NSString class]]) {
            [strM appendFormat:@"%@%@'%@'",where[i],where[i+1],where[i+2]];
        }else{
            [strM appendFormat:@"%@%@%@",where[i],where[i+1],where[i+2]];
        }
        
        if (i != (where.count-3)) {
            [strM appendString:@" and "];
        }
    }
    __block NSUInteger count=0;
    [self executeDB:^(HMDDatabase * _Nonnull db) {
        NSString* SQL = [NSString stringWithFormat:@"select count(*) from %@%@",name,strM];
        [db executeStatements:SQL withResultBlock:^int(NSDictionary *resultsDictionary) {
            count = [[resultsDictionary.allValues lastObject] longLongValue];
            return 0;
        }];
    }];
    return count;
}
/**
 查询该表中有多少条数据
 */
-(long long)countForTable:(NSString* _Nonnull)name where:(NSArray* _Nullable)where{
    NSInteger count = 0;
    @autoreleasepool {
        count = [self countQueueForTable:name where:where];
    }
    return count;
}
/**
 直接传入条件sql语句查询数据条数.
 */
-(long long)__attribute__((annotate("oclint:suppress[block captured instance self]"))) countQueueForTable:(NSString* _Nonnull)name conditions:(NSString* _Nullable)conditions{
    NSAssert(name,@"The name of the table cannot be nil!");
    __block NSUInteger count=0;
    [self executeDB:^(HMDDatabase * _Nonnull db) {
        NSString* SQL = conditions?[NSString stringWithFormat:@"select count(*) from %@ %@",name,conditions]:[NSString stringWithFormat:@"select count(*) from %@",name];
        [db executeStatements:SQL withResultBlock:^int(NSDictionary *resultsDictionary) {
            count = [[resultsDictionary.allValues lastObject] longLongValue];
            return 0;
        }];
    }];
    return count;
}
/**
 直接传入条件sql语句查询数据条数.
 */
-(long long)countForTable:(NSString* _Nonnull)name conditions:(NSString* _Nullable)conditions{
    NSInteger count = 0;
    @autoreleasepool {
        count = [self countQueueForTable:name conditions:conditions];
    }
    return count;
}
/**
 直接调用sqliteb的原生函数计算sun,min,max,avg等.
 */
-(double)__attribute__((annotate("oclint:suppress[block captured instance self]"))) sqliteMethodQueueForTable:(NSString* _Nonnull)name type:(bg_sqliteMethodType)methodType key:(NSString*)key where:(NSString* _Nullable)where{
    NSAssert(name,@"The name of the table cannot be nil!");
    NSAssert(key,@"The name of property named key cannot be nil!");
    __block double num = 0.0;
    NSString* method;
    switch (methodType) {
        case bg_min:
            method = [NSString stringWithFormat:@"min(%@)",key];
            break;
        case bg_max:
            method = [NSString stringWithFormat:@"max(%@)",key];
            break;
        case bg_sum:
            method = [NSString stringWithFormat:@"sum(%@)",key];
            break;
        case bg_avg:
            method = [NSString stringWithFormat:@"avg(%@)",key];
            break;
        default:
            NSAssert(NO,@"Please pass in methodType!");
            break;
    }
    [self executeDB:^(HMDDatabase * _Nonnull db){
        NSString* SQL;
        if(where){
            SQL = [NSString stringWithFormat:@"select %@ from %@ %@",method,name,where];
        }else{
            SQL = [NSString stringWithFormat:@"select %@ from %@",method,name];
        }
        [db executeStatements:SQL withResultBlock:^int(NSDictionary *resultsDictionary){
            id dbResult = [resultsDictionary.allValues lastObject];
            if(dbResult && ![dbResult isKindOfClass:[NSNull class]]) {
                num = [dbResult doubleValue];
            }
            return 0;
        }];
    }];
    return num;
}

/**
 直接调用sqliteb的原生函数计算sun,min,max,avg等.
 */
-(double)sqliteMethodForTable:(NSString* _Nonnull)name type:(bg_sqliteMethodType)methodType key:(NSString*)key where:(NSString* _Nullable)where{
    double num = 0.0;
    @autoreleasepool {
        num = [self sqliteMethodQueueForTable:name type:methodType key:key where:where];
    }
    return num;
}

/**
 keyPath查询数据条数.
 */
-(long long)__attribute__((annotate("oclint:suppress[block captured instance self]"))) countQueueForTable:(NSString* _Nonnull)name forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues{
    NSString* like = [HMDBGTool getLikeWithKeyPathAndValues:keyPathValues where:YES];
    __block NSUInteger count=0;
    [self executeDB:^(HMDDatabase * _Nonnull db) {
        NSString* SQL = [NSString stringWithFormat:@"select count(*) from %@%@",name,like];
        [db executeStatements:SQL withResultBlock:^int(NSDictionary *resultsDictionary) {
            count = [[resultsDictionary.allValues lastObject] longLongValue];
            return 0;
        }];
    }];
    return count;
}

/**
 keyPath查询数据条数.
 */
-(long long)countForTable:(NSString* _Nonnull)name forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues{
    NSInteger count = 0;
    @autoreleasepool {
        count = [self countQueueForTable:name forKeyPathAndValues:keyPathValues];
    }
    return count;
}

-(void)copyA:(NSString* _Nonnull)A toB:(NSString* _Nonnull)B class:(__unsafe_unretained _Nonnull Class)cla keys:(NSArray<NSString*>* const _Nonnull)keys complete:(hmdbg_complete_I)complete{
    //获取"唯一约束"字段名
    NSArray* uniqueKeys = [HMDBGTool executeSelector:hmdbg_uniqueKeysSelector forClass:cla];
    //获取“联合主键”字段名
    NSArray* unionPrimaryKeys = [HMDBGTool executeSelector:hmdbg_unionPrimaryKeysSelector forClass:cla];
    //建立一张临时表
    __block BOOL createFlag = NO;
    [self createTableWithTableName:B keys:keys unionPrimaryKeys:unionPrimaryKeys uniqueKeys:uniqueKeys complete:^(BOOL isSuccess) {
        createFlag = isSuccess;
    }];
    if (!createFlag){
        HMDLog(@"Updating database failed!");
        hmdbg_completeBlock(bg_error);
        return;
    }
    __block bg_dealState refreshstate = bg_error;
    __block BOOL recordError = NO;
    __block BOOL recordSuccess = NO;
    __weak typeof(self) BGSelf = self;
    NSInteger count = [self countQueueForTable:A where:nil];
    
    //如果原来表中没有数据，认为复制成功，即不需要复制
    if (count == 0) {
        recordSuccess = YES;
    }
    
    for(NSInteger i=0;i<count;i+=MaxQueryPageNum){
        @autoreleasepool{//由于查询出来的数据量可能巨大,所以加入自动释放池.
            NSString* param = [NSString stringWithFormat:@"limit %@,%@",@(i),@(MaxQueryPageNum)];
            [self queryWithTableName:A where:param complete:^(NSArray * _Nullable array) {
                for(NSDictionary* oldDict in array){
                    NSMutableDictionary* newDict = [NSMutableDictionary dictionary];
                    for(NSString* keyAndType in keys){
                        NSString* key = [keyAndType componentsSeparatedByString:@"*"][0];
                        if (oldDict[key]){
                            newDict[key] = oldDict[key];
                        }
                    }
                    //将旧表的数据插入到新表
                    [BGSelf insertIntoTableName:B Dict:newDict complete:^(BOOL isSuccess){
                        if (isSuccess){
                            if (!recordSuccess) {
                                recordSuccess = YES;
                            }
                        }else{
                            if (!recordError) {
                                recordError = YES;
                            }
                        }
                        
                    }];
                }
            }];
        }
    }
    
    if (complete){
        if (recordError && recordSuccess) {
            refreshstate = bg_incomplete;
        }else if(recordError && !recordSuccess){
            refreshstate = bg_error;
        }else if (recordSuccess && !recordError){
            refreshstate = bg_complete;
        }else;
        complete(refreshstate);
    }
    
}

-(void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) refreshQueueTable:(NSString* _Nonnull)name class:(__unsafe_unretained _Nonnull Class)cla keys:(NSArray<NSString*>* const _Nonnull)keys complete:(hmdbg_complete_I)complete{
    NSAssert(name,@"The name of the table cannot be nil!");
    NSAssert(keys,@"The NSArray named keys cannnot be nil!");
    [self isExistWithTableName:name complete:^(BOOL isSuccess){
        if (!isSuccess){
            HMDLog(@"No data! Updating database failed!");
            hmdbg_completeBlock(bg_error);
            return;
        }
    }];
    NSString* BGTempTable = @"BGTempTable";
    //事务操作.
    __block int recordFailCount = 0;
    [self executeTransation:^BOOL{
        [self copyA:name toB:BGTempTable class:cla keys:keys complete:^(bg_dealState result) {
            if(result == bg_complete){
                recordFailCount++;
            }
        }];
        [self dropTable:name complete:^(BOOL isSuccess) {
            if(isSuccess)recordFailCount++;
        }];
        [self copyA:BGTempTable toB:name class:cla keys:keys complete:^(bg_dealState result) {
            if(result == bg_complete){
                recordFailCount++;
            }
        }];
        [self dropTable:BGTempTable complete:^(BOOL isSuccess) {
            if(isSuccess)recordFailCount++;
        }];
        if(recordFailCount != 4){
            HMDLog(@"ERROR! Updating database failed!");
        }
        return recordFailCount==4;
    }];
    
    //回调结果.
    if (recordFailCount==0) {
        hmdbg_completeBlock(bg_error);
    }else if (recordFailCount>0&&recordFailCount<4){
        hmdbg_completeBlock(bg_incomplete);
    }else{
        hmdbg_completeBlock(bg_complete);
    }
}

/**
 刷新数据库，即将旧数据库的数据复制到新建的数据库,这是为了去掉没用的字段.
 */
-(void)refreshTable:(NSString* _Nonnull)name class:(__unsafe_unretained _Nonnull Class)cla keys:(NSArray<NSString*>* const _Nonnull)keys complete:(hmdbg_complete_I)complete{
    @autoreleasepool {
        [self refreshQueueTable:name class:cla keys:keys complete:complete];
    }
}

-(void)copyA:(NSString* _Nonnull)A toB:(NSString* _Nonnull)B keyDict:(NSDictionary* const _Nullable)keyDict complete:(hmdbg_complete_I)complete{
    //获取"唯一约束"字段名
    NSArray* uniqueKeys = [HMDBGTool executeSelector:hmdbg_uniqueKeysSelector forClass:NSClassFromString(A)];
    //获取“联合主键”字段名
    NSArray* unionPrimaryKeys = [HMDBGTool executeSelector:hmdbg_unionPrimaryKeysSelector forClass:NSClassFromString(A)];
    __block NSArray* keys = [HMDBGTool getClassIvarList:NSClassFromString(A) onlyKey:NO];
    NSArray* newKeys = keyDict.allKeys;
    NSArray* oldKeys = keyDict.allValues;
    //建立一张临时表
    __block BOOL createFlag = NO;
    [self createTableWithTableName:B keys:keys unionPrimaryKeys:unionPrimaryKeys uniqueKeys:uniqueKeys complete:^(BOOL isSuccess) {
        createFlag = isSuccess;
    }];
    if (!createFlag){
        HMDLog(@"Updating database failed!");
        hmdbg_completeBlock(bg_error);
        return;
    }
    
    __block bg_dealState refreshstate = bg_error;
    __block BOOL recordError = NO;
    __block BOOL recordSuccess = NO;
    __weak typeof(self) BGSelf = self;
    NSInteger count = [self countQueueForTable:A where:nil];
    for(NSInteger i=0;i<count;i+=MaxQueryPageNum){
        @autoreleasepool{//由于查询出来的数据量可能巨大,所以加入自动释放池.
            NSString* param = [NSString stringWithFormat:@"limit %@,%@",@(i),@(MaxQueryPageNum)];
            [self queryWithTableName:A where:param complete:^(NSArray * _Nullable array) {
                __strong typeof(BGSelf) strongSelf = BGSelf;
                for(NSDictionary* oldDict in array){
                    NSMutableDictionary* newDict = [NSMutableDictionary dictionary];
                    for(NSString* keyAndType in keys){
                        NSString* key = [keyAndType componentsSeparatedByString:@"*"][0];
                        if (oldDict[key]){
                            newDict[key] = oldDict[key];
                        }
                    }
                    for(int i=0;i<oldKeys.count;i++){
                        //字段名前加上 @"BG_"
                        NSString* oldkey = oldKeys[i];
                        NSString* newkey = newKeys[i];
                        if (oldDict[oldkey]){
                            newDict[newkey] = oldDict[oldkey];
                        }
                    }
                    //将旧表的数据插入到新表
                    [strongSelf insertIntoTableName:B Dict:newDict complete:^(BOOL isSuccess){
                        
                        if (isSuccess){
                            if (!recordSuccess) {
                                recordSuccess = YES;
                            }
                        }else{
                            if (!recordError) {
                                recordError = YES;
                            }
                        }
                    }];
                }
                
            }];
        }
    }
    
    if (complete){
        if (recordError && recordSuccess) {
            refreshstate = bg_incomplete;
        }else if(recordError && !recordSuccess){
            refreshstate = bg_error;
        }else if (recordSuccess && !recordError){
            refreshstate = bg_complete;
        }else;
        complete(refreshstate);
    }
    
    
}

-(void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) refreshQueueTable:(NSString* _Nonnull)tablename class:(__unsafe_unretained _Nonnull Class)cla keys:(NSArray* const _Nonnull)keys keyDict:(NSDictionary* const _Nonnull)keyDict complete:(hmdbg_complete_I)complete{
    NSAssert(tablename,@"The name of the table cannot be nil!");
    NSAssert(keyDict,@"The NSDictionary contains the mapping variable name cannot be nil!");
    [self isExistWithTableName:tablename complete:^(BOOL isSuccess){
        if (!isSuccess){
            HMDLog(@"No data! Updating database failed!");
            hmdbg_completeBlock(bg_error);
            return;
        }
    }];
    
    //事务操作.
    NSString* BGTempTable = @"BGTempTable";
    __block int recordFailCount = 0;
    [self executeTransation:^BOOL{
        [self copyA:tablename toB:BGTempTable keyDict:keyDict complete:^(bg_dealState result) {
            if(result == bg_complete){
                recordFailCount++;
            }
        }];
        [self dropTable:tablename complete:^(BOOL isSuccess) {
            if(isSuccess)recordFailCount++;
        }];
        [self copyA:BGTempTable toB:tablename class:cla keys:keys complete:^(bg_dealState result) {
            if(result == bg_complete){
                recordFailCount++;
            }
        }];
        [self dropTable:BGTempTable complete:^(BOOL isSuccess) {
            if(isSuccess)recordFailCount++;
        }];
        if (recordFailCount != 4) {
            HMDLog(@"ERROR! Updating database failed!");
        }
        return recordFailCount==4;
    }];
    
    //回调结果.
    if(recordFailCount==0){
        hmdbg_completeBlock(bg_error);
    }else if (recordFailCount>0&&recordFailCount<4){
        hmdbg_completeBlock(bg_incomplete);
    }else{
        hmdbg_completeBlock(bg_complete);
    }
    
}

-(void)refreshTable:(NSString* _Nonnull)name class:(__unsafe_unretained _Nonnull Class)cla keys:(NSArray* const _Nonnull)keys keyDict:(NSDictionary* const _Nonnull)keyDict complete:(hmdbg_complete_I)complete{
    @autoreleasepool {
        [self refreshQueueTable:name class:cla keys:keys keyDict:keyDict complete:complete];
    }
}

/**
 判断类属性是否有改变,智能刷新.
 */
-(void)ifIvarChangeForObject:(id)object ignoredKeys:(NSArray*)ignoredkeys{
    //获取缓存的属性信息
    NSCache* cache = [NSCache hmdbg_cache];
    NSString* cacheKey = [NSString stringWithFormat:@"%@_IvarChangeState",[object class]];
    id IvarChangeState = [cache objectForKey:cacheKey];
    if(IvarChangeState){
        return;
    }else{
        [cache setObject:@(YES) forKey:cacheKey];
    }
    
    @autoreleasepool {
        //获取表名
        NSString* tableName = [HMDBGTool getTableNameWithObject:object];
        NSMutableArray* newKeys = [NSMutableArray array];
        NSMutableArray* sqlKeys = [NSMutableArray array];
        [self executeDB:^(HMDDatabase * _Nonnull db) {
                NSString* SQL = [NSString stringWithFormat:@"select sql from sqlite_master where tbl_name='%@' and type='table';",tableName];
                NSMutableArray* tempArrayM = [NSMutableArray array];
                //获取表格所有列名.
                [db executeStatements:SQL withResultBlock:^int(NSDictionary *resultsDictionary) {
                    NSString* allName = [resultsDictionary.allValues lastObject];
                    allName = [allName stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                    NSRange range1 = [allName rangeOfString:@"("];
                    allName = [allName substringFromIndex:range1.location+1];
                    NSRange range2 = [allName rangeOfString:@")"];
                    allName = [allName substringToIndex:range2.location];
                    NSArray* sqlNames = [allName componentsSeparatedByString:@","];
                    
                    for(NSString* sqlName in sqlNames){
                        NSString* columnName = [[[sqlName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsSeparatedByString:@" "] firstObject];
                        if (columnName) {
                            [tempArrayM addObject:columnName];
                        }
                        else {
#ifdef DEBUG
                            fprintf(stderr,"BDGM ifIvarChangeForObject add null columnName");
#endif
                        }
                    }
                    return 0;
                }];
                NSArray* columNames = tempArrayM.count?tempArrayM:nil;
                NSArray* keyAndtypes = [HMDBGTool getClassIvarList:[object class] onlyKey:NO];
                for(NSString* keyAndtype in keyAndtypes){
                    NSString* key = [[keyAndtype componentsSeparatedByString:@"*"] firstObject];
                    if(ignoredkeys && [ignoredkeys containsObject:key])continue;
                    
                    if (![columNames containsObject:key]) {
                        [newKeys addObject:keyAndtype];
                    }
                }
                
                NSMutableArray* keys = [NSMutableArray arrayWithArray:[HMDBGTool getClassIvarList:[object class] onlyKey:YES]];
                if (ignoredkeys) {
                    [keys removeObjectsInArray:ignoredkeys];
                }
                [columNames enumerateObjectsUsingBlock:^(NSString* _Nonnull columName, NSUInteger idx, BOOL * _Nonnull stop) {
                    if(![keys containsObject:columName]){
                        [sqlKeys addObject:columName];
                    }
                }];
            
        }];
        
        if((sqlKeys.count==0) && (newKeys.count>0)){
            //此处只是增加了新的列.
            for(NSString* key in newKeys){
                //添加新字段
                [self addTable:tableName key:key complete:^(BOOL isSuccess){}];
            }
        }else if(sqlKeys.count>0){
            //字段发生改变,减少或名称变化,实行刷新数据库.
            NSMutableArray* newTableKeys = [[NSMutableArray alloc] initWithArray:[HMDBGTool getClassIvarList:[object class] onlyKey:NO]];
            NSMutableArray* tempIgnoreKeys = [[NSMutableArray alloc] initWithArray:ignoredkeys];
            for(int i=0;i<newTableKeys.count;i++){
                NSString* key = [[newTableKeys[i] componentsSeparatedByString:@"*"] firstObject];
                if([tempIgnoreKeys containsObject:key]) {
                    [newTableKeys removeObject:newTableKeys[i]];
                    [tempIgnoreKeys removeObject:key];
                    i--;
                }
                if(tempIgnoreKeys.count == 0){
                    break;
                }
            }
            [self refreshQueueTable:tableName class:[object class] keys:newTableKeys complete:nil];
        }else;
    }
}


/**
 处理插入的字典数据并返回
 */
-(void)insertWithObject:(id)object ignoredKeys:(NSArray* const _Nullable)ignoredKeys complete:(hmdbg_complete_B)complete{
    NSDictionary* dictM = [HMDBGTool getDictWithObject:object ignoredKeys:ignoredKeys filtModelInfoType:bg_ModelInfoInsert];
    //自动判断是否有字段改变,自动刷新数据库.
    [self ifIvarChangeForObject:object ignoredKeys:ignoredKeys];
    NSString* tableName = [HMDBGTool getTableNameWithObject:object];
    [self insertIntoTableName:tableName Dict:dictM complete:complete];
    
}

-(NSArray*)getArray:(NSArray*)array ignoredKeys:(NSArray* const _Nullable)ignoredKeys filtModelInfoType:(bg_getModelInfoType)filtModelInfoType{
    NSMutableArray* dictArray = [NSMutableArray array];
    [array enumerateObjectsUsingBlock:^(id  _Nonnull object, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary* dict = [HMDBGTool getDictWithObject:object ignoredKeys:ignoredKeys filtModelInfoType:filtModelInfoType];
        [dictArray addObject:dict];
    }];
    return dictArray;
}

/**
 批量插入数据
 */
-(void)insertWithObjects:(NSArray*)array ignoredKeys:(NSArray* const _Nullable)ignoredKeys complete:(hmdbg_complete_B)complete{
    NSArray* dictArray = [self getArray:array ignoredKeys:ignoredKeys filtModelInfoType:bg_ModelInfoInsert];
    //自动判断是否有字段改变,自动刷新数据库.
    [self ifIvarChangeForObject:array.firstObject ignoredKeys:ignoredKeys];
    NSString* tableName = [HMDBGTool getTableNameWithObject:array.firstObject];
    [self insertIntoTableName:tableName DictArray:dictArray complete:complete];
}
/**
 批量更新数据.
 over
 */
-(void)updateSetWithObjects:(NSArray*)array ignoredKeys:(NSArray* const _Nullable)ignoredKeys complete:(hmdbg_complete_B)complete{
    NSArray* dictArray = [self getArray:array ignoredKeys:ignoredKeys filtModelInfoType:bg_ModelInfoArrayUpdate];
    NSString* tableName = [HMDBGTool getTableNameWithObject:array.firstObject];
    [self updateSetTableName:tableName class:[array.firstObject class] DictArray:dictArray complete:complete];
}

/**
 批量存储.
 */
-(void)saveObjects:(NSArray* _Nonnull)array ignoredKeys:(NSArray* const _Nullable)ignoredKeys complete:(hmdbg_complete_B)complete{
    @autoreleasepool {
        [self ifNotExistWillCreateTableWithObject:array.firstObject ignoredKeys:ignoredKeys];
        [self insertWithObjects:array ignoredKeys:ignoredKeys complete:complete];
    }
}
/**
 批量更新.
 over
 */
-(void)updateObjects:(NSArray* _Nonnull)array ignoredKeys:(NSArray* const _Nullable)ignoredKeys complete:(hmdbg_complete_B)complete{
    @autoreleasepool {
        [self updateSetWithObjects:array ignoredKeys:ignoredKeys complete:complete];
    }
}
/**
 批量插入或更新.
 */
-(void)bg_saveOrUpateArray:(NSArray* _Nonnull)array ignoredKeys:(NSArray* const _Nullable)ignoredKeys complete:(hmdbg_complete_B)complete{
    @autoreleasepool {
        //判断是否建表.
        [self ifNotExistWillCreateTableWithObject:array.firstObject ignoredKeys:ignoredKeys];
        //自动判断是否有字段改变,自动刷新数据库.
        [self ifIvarChangeForObject:array.firstObject ignoredKeys:ignoredKeys];
        //转换模型数据
        NSArray* dictArray = [self getArray:array ignoredKeys:ignoredKeys filtModelInfoType:bg_ModelInfoNone];
        //获取自定义表名
        NSString* tableName = [HMDBGTool getTableNameWithObject:array.firstObject];
        [self bg_saveOrUpdateWithTableName:tableName class:[array.firstObject class] DictArray:dictArray complete:complete];
    }
}

/**
 存储一个对象.
 */
-(void)saveObject:(id _Nonnull)object ignoredKeys:(NSArray* const _Nullable)ignoredKeys complete:(hmdbg_complete_B)complete{
    @autoreleasepool {
        [self ifNotExistWillCreateTableWithObject:object ignoredKeys:ignoredKeys];
        [self insertWithObject:object ignoredKeys:ignoredKeys complete:complete];
    }
}

-(void)queryObjectQueueWithTableName:(NSString* _Nonnull)tablename class:(__unsafe_unretained _Nonnull Class)cla where:(NSString* _Nullable)where complete:(hmdbg_complete_A)complete{
    //检查是否建立了跟对象相对应的数据表
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tablename complete:^(BOOL isExist) {
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就返回空
            hmdbg_completeBlock(nil);
        }else{
            [strongSelf queryWithTableName:tablename where:where complete:^(NSArray * _Nullable array) {
                NSArray* resultArray = [HMDBGTool tansformDataFromSqlDataWithTableName:tablename class:cla array:array];
                hmdbg_completeBlock(resultArray);
            }];
        }
    }];
}
/**
 查询对象.
 */
-(void)queryObjectWithTableName:(NSString* _Nonnull)tablename class:(__unsafe_unretained _Nonnull Class)cla where:(NSString* _Nullable)where complete:(hmdbg_complete_A)complete{
    @autoreleasepool {
        [self queryObjectQueueWithTableName:tablename class:cla where:where complete:complete];
    }
}

-(void)updateQueueWithObject:(id _Nonnull)object where:(NSArray* _Nullable)where ignoreKeys:(NSArray* const _Nullable)ignoreKeys complete:(hmdbg_complete_B)complete{
    NSDictionary* valueDict = [HMDBGTool getDictWithObject:object ignoredKeys:ignoreKeys filtModelInfoType:bg_ModelInfoSingleUpdate];
    NSString* tableName = [HMDBGTool getTableNameWithObject:object];
    __block BOOL result = NO;
    [self isExistWithTableName:tableName complete:^(BOOL isExist){
        result = isExist;
    }];
    
    if (!result){
        //如果不存在就返回NO
        hmdbg_completeBlock(NO);
    }else{
        //自动判断是否有字段改变,自动刷新数据库.
        [self ifIvarChangeForObject:object ignoredKeys:ignoreKeys];
        [self updateWithTableName:tableName valueDict:valueDict where:where complete:complete];
    }
    
}

/**
 根据条件改变对象数据.
 */
-(void)updateWithObject:(id _Nonnull)object where:(NSArray* _Nullable)where ignoreKeys:(NSArray* const _Nullable)ignoreKeys complete:(hmdbg_complete_B)complete{
    @autoreleasepool {
        [self updateQueueWithObject:object where:where ignoreKeys:ignoreKeys complete:complete];
    }
}

-(void)updateQueueWithObject:(id _Nonnull)object forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues ignoreKeys:(NSArray* const _Nullable)ignoreKeys complete:(hmdbg_complete_B)complete{
    NSDictionary* valueDict = [HMDBGTool getDictWithObject:object ignoredKeys:ignoreKeys filtModelInfoType:bg_ModelInfoSingleUpdate];
    NSString* tableName = [HMDBGTool getTableNameWithObject:object];
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tableName complete:^(BOOL isExist){
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就返回NO
            hmdbg_completeBlock(NO);
        }else{
            [strongSelf updateWithTableName:tableName forKeyPathAndValues:keyPathValues valueDict:valueDict complete:complete];
        }
    }];
}

/**
 根据keyPath改变对象数据.
 */
-(void)updateWithObject:(id _Nonnull)object forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues ignoreKeys:(NSArray* const _Nullable)ignoreKeys complete:(hmdbg_complete_B)complete{
    @autoreleasepool {
        //自动判断是否有字段改变,自动刷新数据库.
        [self ifIvarChangeForObject:object ignoredKeys:ignoreKeys];
        [self updateQueueWithObject:object forKeyPathAndValues:keyPathValues ignoreKeys:ignoreKeys complete:complete];
    }
}

/**
 根据类删除此类所有表数据.
 */
-(void)clearWithObject:(id _Nonnull)object complete:(hmdbg_complete_B)complete{
    NSString* tableName = [HMDBGTool getTableNameWithObject:object];
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tableName complete:^(BOOL isExist) {
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就相当于清空,返回YES
            hmdbg_completeBlock(YES);
        }else{
            [strongSelf clearTable:tableName complete:complete];
        }
    }];
}
/**
 根据类,删除这个类的表.
 */
-(void)dropWithTableName:(NSString* _Nonnull)tablename complete:(hmdbg_complete_B)complete{
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tablename complete:^(BOOL isExist){
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就返回NO
            hmdbg_completeBlock(NO);
        }else{
            [strongSelf dropTable:tablename complete:complete];
        }
    }];
}

-(void)__attribute__((annotate("oclint:suppress[block captured instance self]")))
 copyQueueTable:(NSString* _Nonnull)srcTable to:(NSString* _Nonnull)destTable keyDict:(NSDictionary* const _Nonnull)keydict append:(BOOL)append complete:(hmdbg_complete_I)complete{
    NSAssert(![srcTable isEqualToString:destTable],@"Cannot copy the date of this table to itself!");
    NSArray* destKeys = keydict.allValues;
    NSArray* srcKeys = keydict.allKeys;
    [self isExistWithTableName:srcTable complete:^(BOOL isExist) {
        NSAssert(isExist,@"There is no data in origin table! Copy failed!");
    }];
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:destTable complete:^(BOOL isExist) {
        if(!isExist){
            NSAssert(NO,@"The target table doesn't exist! Copy failed!");
        }else{
            if (!append){//覆盖模式,即将原数据删掉,拷贝新的数据过来
                [BGSelf clearTable:destTable complete:nil];
            }
        }
    }];
    __block bg_dealState copystate = bg_error;
    __block BOOL recordError = NO;
    __block BOOL recordSuccess = NO;
    NSInteger srcCount = [self countQueueForTable:srcTable where:nil];
    for(NSInteger i=0;i<srcCount;i+=MaxQueryPageNum){
        @autoreleasepool{//由于查询出来的数据量可能巨大,所以加入自动释放池.
            NSString* param = [NSString stringWithFormat:@"limit %@,%@",@(i),@(MaxQueryPageNum)];
            [self queryWithTableName:srcTable where:param complete:^(NSArray * _Nullable array) {
                for(NSDictionary* srcDict in array){
                    NSMutableDictionary* destDict = [NSMutableDictionary dictionary];
                    for(int i=0;i<srcKeys.count;i++){
                        NSString* destSqlKey = destKeys[i];
                        NSString* srcSqlKey = srcKeys[i];
                        destDict[destSqlKey] = srcDict[srcSqlKey];
                    }
                    [BGSelf insertIntoTableName:destTable Dict:destDict complete:^(BOOL isSuccess) {
                        if (isSuccess){
                            if (!recordSuccess) {
                                recordSuccess = YES;
                            }
                        }else{
                            if (!recordError) {
                                recordError = YES;
                            }
                        }
                    }];
                }
            }];
        }
    }
    
    if (complete){
        if (recordError && recordSuccess) {
            copystate = bg_incomplete;
        }else if(recordError && !recordSuccess){
            copystate = bg_error;
        }else if (recordSuccess && !recordError){
            copystate = bg_complete;
        }else;
        complete(copystate);
    }
    
}

/**
 将某表的数据拷贝给另一个表
 */
-(void)copyTable:(NSString* _Nonnull)srcTable to:(NSString* _Nonnull)destTable keyDict:(NSDictionary* const _Nonnull)keydict append:(BOOL)append complete:(hmdbg_complete_I)complete{
    @autoreleasepool {
        [self copyQueueTable:srcTable to:destTable keyDict:keydict append:append complete:complete];
    }
}
/**
 直接执行sql语句.
 @tablename 要操作的表名.
 @cla 要操作的类.
 */
-(id _Nullable)__attribute__((annotate("oclint:suppress[block captured instance self]"))) bg_executeSql:(NSString* const _Nonnull)sql tablename:(NSString* _Nonnull)tablename class:(__unsafe_unretained _Nonnull Class)cla{
    NSAssert(sql,@"SQL statement cannot be empty!");
    __block id result;
    [self executeDB:^(HMDDatabase * _Nonnull db){
        if([[sql lowercaseString] hasPrefix:@"select"]){
            // 1.查询数据
            HMDResultSet *rs = [db executeQuery:sql];
            if (rs == nil) {
                HMDLog(@"QUERY ERROR! Data doesn't exist! Please read data after data stored!");
                result = nil;
            }else{
                result = [NSMutableArray array];
            }
            result = [NSMutableArray array];
            // 2.遍历结果集
            while (rs.next) {
                NSMutableDictionary* dictM = [[NSMutableDictionary alloc] init];
                NSUInteger keyCount = [[[rs columnNameToIndexMap] allKeys] count];
                for (int i=0;i<keyCount;i++) {
                    dictM[[rs columnNameForIndex:i]] = [rs objectForColumnIndex:i];
                }
                [result addObject:dictM];
            }
            //查询完后要关闭rs，不然会报@"Warning: there is at least one open result set around after performing
            [rs close];
            //转换结果
            result = [HMDBGTool tansformDataFromSqlDataWithTableName:tablename class:cla array:result];
        }else{
            result = @([db executeUpdate:sql]);
        }
    }];
    return result;
}
#pragma mark Store Array

/**
 直接存储数组.
 */
-(void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) saveArray:(NSArray* _Nonnull)array name:(NSString*)name complete:(hmdbg_complete_B)complete{
    NSAssert(array&&array.count,@"The array can not be nil!");
    NSAssert(name,@"The name of unique identification cannot be empty!");
    @autoreleasepool {
        __weak typeof(self) BGSelf = self;
        [self isExistWithTableName:name complete:^(BOOL isSuccess) {
            if (!isSuccess) {
                [BGSelf createTableWithTableName:name keys:@[[NSString stringWithFormat:@"%@*i",hmdbg_primaryKey],@"param*@\"NSString\"",@"index*i"] unionPrimaryKeys:nil uniqueKeys:nil complete:nil];
            }
        }];
        __block NSInteger sqlCount = [self countQueueForTable:name where:nil];
        
        __block NSInteger num = 0;
        [self executeTransation:^BOOL{
            for(id value in array){
                NSString* type = [NSString stringWithFormat:@"@\"%@\"",NSStringFromClass([value class])];
                id sqlValue = [HMDBGTool getSqlValue:value type:type encode:YES];
                sqlValue = [NSString stringWithFormat:@"%@$$$%@",sqlValue,type];
                NSDictionary* dict = @{@"BG_param":sqlValue,@"BG_index":@(sqlCount++)};
                [self insertIntoTableName:name Dict:dict complete:^(BOOL isSuccess) {
                    if(isSuccess) {
                        num++;
                    }
                }];
            }
            return YES;
        }];
        hmdbg_completeBlock(array.count==num);
    }
}
/**
 读取数组.
 */
-(void)queryArrayWithName:(NSString*)name complete:(hmdbg_complete_A)complete{
    NSAssert(name,@"The name of unique identification cannot be empty!");
    @autoreleasepool {
        NSString* condition = [NSString stringWithFormat:@"order by %@ asc",hmdbg_sqlKey(hmdbg_primaryKey)];
        [self queryQueueWithTableName:name conditions:condition complete:^(NSArray * _Nullable array) {
            NSMutableArray* resultM = nil;
            if(array&&array.count){
                resultM = [NSMutableArray array];
                for(NSDictionary* dict in array){
                    NSArray* keyAndTypes = [dict[@"BG_param"] componentsSeparatedByString:@"$$$"];
                    id value = [keyAndTypes firstObject];
                    NSString* type = [keyAndTypes lastObject];
                    value = [HMDBGTool getSqlValue:value type:type encode:NO];
                    [resultM hmd_addObject:value];
                }
            }
            hmdbg_completeBlock(resultM);
        }];
    }
}
/**
 读取数组某个元素.
 */
-(id _Nullable)queryArrayWithName:(NSString* _Nonnull)name index:(NSInteger)index{
    NSAssert(name,@"The name of unique identification cannot be empty!");
    __block id resultValue = nil;
    @autoreleasepool {
        [self queryQueueWithTableName:name conditions:[NSString stringWithFormat:@"where BG_index=%@",@(index)] complete:^(NSArray * _Nullable array){
            if(array&&array.count){
                NSDictionary* dict = [array firstObject];
                NSArray* keyAndTypes = [dict[@"BG_param"] componentsSeparatedByString:@"$$$"];
                id value = [keyAndTypes firstObject];
                NSString* type = [keyAndTypes lastObject];
                resultValue = [HMDBGTool getSqlValue:value type:type encode:NO];
            }
        }];
    }
    return resultValue;
}
/**
 更新数组某个元素.
 */
-(BOOL)updateObjectWithName:(NSString* _Nonnull)name object:(id _Nonnull)object index:(NSInteger)index{
    NSAssert(name,@"The name of unique identification cannot be empty!");
    NSAssert(object,@"The element cannot be nil!");
    __block BOOL result = NO;
    @autoreleasepool{
        NSString* type = [NSString stringWithFormat:@"@\"%@\"",NSStringFromClass([object class])];
        id sqlValue = [HMDBGTool getSqlValue:object type:type encode:YES];
        sqlValue = [NSString stringWithFormat:@"%@$$$%@",sqlValue,type];
        NSDictionary* dict = @{@"BG_param":sqlValue};
        [self updateWithTableName:name valueDict:dict where:@[@"index",@"=",@(index)] complete:^(BOOL isSuccess) {
            result = isSuccess;
        }];
    }
    return result;
}
/**
 删除数组某个元素.
 */
-(BOOL)__attribute__((annotate("oclint:suppress[block captured instance self]"))) deleteObjectWithName:(NSString* _Nonnull)name index:(NSInteger)index{
    NSAssert(name,@"The name of unique identification cannot be empty!");
    __block NSInteger flag = 0;
    @autoreleasepool {
        [self executeTransation:^BOOL{
            [self deleteQueueWithTableName:name conditions:[NSString stringWithFormat:@"where BG_index=%@",@(index)] complete:^(BOOL isSuccess) {
                if(isSuccess) {
                    flag++;
                }
            }];
            if(flag){
                [self updateQueueWithTableName:name valueDict:nil conditions:[NSString stringWithFormat:@"set BG_index=BG_index-1 where BG_index>%@",@(index)] complete:^(BOOL isSuccess) {
                    if(isSuccess) {
                        flag++;
                    }
                }];
            }
            return flag==2;
        }];
    }
    return flag==2;
}
#pragma mark Store Dictionary
/**
 直接存储字典.
 */
-(void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) saveDictionary:(NSDictionary* _Nonnull)dictionary complete:(hmdbg_complete_B)complete{
    NSAssert(dictionary||dictionary.allKeys.count,@"The Dictionary cannot be nil!");
    @autoreleasepool {
        NSString* const tableName = @"BG_Dictionary";
        [self isExistWithTableName:tableName complete:^(BOOL isSuccess) {
            if (!isSuccess) {
                [self createTableWithTableName:tableName keys:@[[NSString stringWithFormat:@"%@*i",hmdbg_primaryKey],@"key*@\"NSString\"",@"value*@\"NSString\""] unionPrimaryKeys:nil uniqueKeys:@[@"key"] complete:nil];
            }
        }];
        __block NSInteger num = 0;
        
        [self executeTransation:^BOOL{
            [dictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop){
                NSString* type = [NSString stringWithFormat:@"@\"%@\"",NSStringFromClass([value class])];
                id sqlValue = [HMDBGTool getSqlValue:value type:type encode:YES];
                sqlValue = [NSString stringWithFormat:@"%@$$$%@",sqlValue,type];
                NSDictionary* dict = @{@"BG_key":key,@"BG_value":sqlValue};
                [self insertIntoTableName:tableName Dict:dict complete:^(BOOL isSuccess) {
                    if(isSuccess) {
                        num++;
                    }
                }];
            }];
            return YES;
        }];
        hmdbg_completeBlock(dictionary.allKeys.count==num);
    }
}
/**
 添加字典元素.
 */
-(BOOL)bg_setValue:(id _Nonnull)value forKey:(NSString* const _Nonnull)key{
    NSAssert(key,@"key cannot be nil!");
    NSAssert(value,@"value cannot be nil!");
    NSDictionary* dict = @{key:value};
    __block BOOL result = NO;
    [self saveDictionary:dict complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    return result;
}
/**
 更新字典元素.
 */
-(BOOL)bg_updateValue:(id _Nonnull)value forKey:(NSString* const _Nonnull)key{
    NSAssert(key,@"key cannot be nil!");
    NSAssert(value,@"value cannot be nil!");
    __block BOOL result = NO;
    @autoreleasepool{
        NSString* type = [NSString stringWithFormat:@"@\"%@\"",NSStringFromClass([value class])];
        id sqlvalue = [HMDBGTool getSqlValue:value type:type encode:YES];
        sqlvalue = [NSString stringWithFormat:@"%@$$$%@",sqlvalue,type];
        NSDictionary* dict = @{@"BG_value":sqlvalue};
        NSString* const tableName = @"BG_Dictionary";
        [self updateWithTableName:tableName valueDict:dict where:@[@"key",@"=",key] complete:^(BOOL isSuccess) {
            result = isSuccess;
        }];
    }
    return result;
}
/**
 遍历字典元素.
 */
-(void)bg_enumerateKeysAndObjectsUsingBlock:(void (^ _Nonnull)(NSString* _Nonnull key, id _Nonnull value,BOOL *stop))block{
    @autoreleasepool{
        NSString* const tableName = @"BG_Dictionary";
        NSString* condition = [NSString stringWithFormat:@"order by %@ asc",hmdbg_sqlKey(hmdbg_primaryKey)];
        [self queryQueueWithTableName:tableName conditions:condition complete:^(NSArray * _Nullable array) {
            BOOL stopFlag = NO;
            for(NSDictionary* dict in array){
                NSArray* keyAndTypes = [dict[@"BG_value"] componentsSeparatedByString:@"$$$"];
                NSString* key = dict[@"BG_key"];
                id value = [keyAndTypes firstObject];
                NSString* type = [keyAndTypes lastObject];
                value = [HMDBGTool getSqlValue:value type:type encode:NO];
                !block?:block(key,value,&stopFlag);
                if(stopFlag){
                    break;
                }
            }
        }];
    }
}
/**
 获取字典元素.
 */
-(id _Nullable)bg_valueForKey:(NSString* const _Nonnull)key{
    NSAssert(key,@"key cannot be nil!");
    __block id resultValue = nil;
    @autoreleasepool {
        NSString* const tableName = @"BG_Dictionary";
        [self queryQueueWithTableName:tableName conditions:[NSString stringWithFormat:@"where BG_key='%@'",key] complete:^(NSArray * _Nullable array){
            if(array&&array.count){
                NSDictionary* dict = [array firstObject];
                NSArray* keyAndTypes = [dict[@"BG_value"] componentsSeparatedByString:@"$$$"];
                id value = [keyAndTypes firstObject];
                NSString* type = [keyAndTypes lastObject];
                resultValue = [HMDBGTool getSqlValue:value type:type encode:NO];
            }
        }];
    }
    return resultValue;
}
/**
 删除字典元素.
 */
-(BOOL)bg_deleteValueForKey:(NSString* const _Nonnull)key{
    NSAssert(key,@"key cannot be nil!");
    __block BOOL result = NO;
    @autoreleasepool {
        NSString* const tableName = @"BG_Dictionary";
        [self deleteQueueWithTableName:tableName conditions:[NSString stringWithFormat:@"where BG_key='%@'",key] complete:^(BOOL isSuccess) {
            result = isSuccess;
        }];
    }
    return result;
}

- (BOOL)__attribute__((annotate("oclint:suppress[block captured instance self]"))) ifNotExistWillCreateTableWithObject:(id)object ignoredKeys:(NSArray* const)ignoredKeys {
    //检查是否建立了跟对象相对应的数据表
    NSString* tableName = [HMDBGTool getTableNameWithObject:object];
    //获取"唯一约束"字段名
    NSArray* uniqueKeys = [HMDBGTool executeSelector:hmdbg_uniqueKeysSelector forClass:[object class]];
    //获取“联合主键”字段名
    NSArray* unionPrimaryKeys = [HMDBGTool executeSelector:hmdbg_unionPrimaryKeysSelector forClass:[object class]];
    __block BOOL isExistTable = NO;
    
    [self isExistWithTableName:tableName complete:^(BOOL isExist) {
        if (!isExist){//如果不存在就新建
            NSArray* createKeys = [HMDBGTool bg_filtCreateKeys:[HMDBGTool getClassIvarList:[object class] onlyKey:NO] ignoredkeys:ignoredKeys];
            [self createTableWithTableName:tableName keys:createKeys unionPrimaryKeys:unionPrimaryKeys uniqueKeys:uniqueKeys complete:^(BOOL isSuccess) {
                isExistTable = isSuccess;
            }];
        }
    }];
    
    return isExistTable;
}

- (void)vacuumDB {
    [self.queue inDatabase:^(HMDDatabase * _Nonnull db) {
        [db executeStatements:@"VACUUM"];
    }];
}

- (NSInteger)deleteErrorCode {
    return _delteErrorCode;
}

@end
