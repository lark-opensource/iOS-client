//
//  HMDStoreIMP.h
//  Heimdallr
//
//  Created by fengyadong on 2018/6/11.
//

#import <Foundation/Foundation.h>
#import "HMDStoreCondition.h"

typedef NS_ENUM(NSInteger, HMDConditionOrder)
{
    HMDOrderDescending,
    HMDOrderAscending,
};


@protocol HMDStoreIMP <NSObject>

- (NSString *_Nonnull)rootPath;

//create
- (BOOL)createTable:(NSString *_Nonnull)tableName withClass:(__unsafe_unretained Class _Nonnull )cls;

//add
- (BOOL)insertObject:(id _Nonnull )object
                into:(NSString *_Nonnull)tableName;

- (BOOL)insertObjects:(NSArray<id> *_Nonnull)objects
                 into:(NSString *_Nonnull)tableName;

//query
- (id _Nullable)getOneObjectWithTableName:(NSString *_Nonnull)tablename
                                   class:(__unsafe_unretained Class _Nonnull)cls
                           andConditions:(NSArray<HMDStoreCondition *> * _Nullable)andConditions
                            orConditions:(NSArray<HMDStoreCondition *> * _Nullable)orConditions;

- (NSArray<id> * _Nullable)getAllObjectsWithTableName:(NSString *_Nonnull)tablename
                                               class:(__unsafe_unretained Class _Nonnull)cls;

- (NSArray<id> * _Nullable)getObjectsWithTableName:(NSString *_Nonnull)tablename
                                            class:(__unsafe_unretained Class _Nonnull)cls
                                    andConditions:(NSArray<HMDStoreCondition *> * _Nullable)andConditions
                                     orConditions:(NSArray<HMDStoreCondition *> * _Nullable)orConditions;

- (NSArray<id> * _Nullable)getObjectsWithTableName:(NSString *_Nonnull)tablename
                                            class:(__unsafe_unretained Class _Nonnull)cls
                                    andConditions:(NSArray<HMDStoreCondition *> * _Nullable)andConditions
                                     orConditions:(NSArray<HMDStoreCondition *> * _Nullable)orConditions
                                 orderingProperty:(NSString * _Nullable)orderingProperty
                                     orderingType:(HMDConditionOrder)orderingType;

- (NSArray<id> * _Nullable)getObjectsWithTableName:(NSString *_Nonnull)tablename
                                            class:(__unsafe_unretained Class _Nonnull)cls
                                    andConditions:(NSArray<HMDStoreCondition *> * _Nullable)andConditions
                                     orConditions:(NSArray<HMDStoreCondition *> * _Nullable)orConditions
                                            limit:(NSInteger)limitCount;


//delete
- (BOOL)deleteAllObjectsFromTable:(NSString *_Nonnull)tableName;

- (BOOL)dropTable:(NSString *_Nonnull)tableName;

- (BOOL)deleteObjectsFromTable:(NSString *_Nonnull)tableName
                 andConditions:(NSArray<HMDStoreCondition *> * _Nullable)andConditions
                  orConditions:(NSArray<HMDStoreCondition *> * _Nullable)orConditions;

- (BOOL)deleteObjectsFromTable:(NSString *_Nonnull)tableName
                 andConditions:(NSArray<HMDStoreCondition *> * _Nullable)andConditions
                  orConditions:(NSArray<HMDStoreCondition *> * _Nullable)orConditions
                         limit:(NSInteger)limitCount;

- (BOOL)deleteObjectsFromTable:(NSString *_Nonnull)tableName
                limitToMaxSize:(long long)maxSize;

//update
- (BOOL)updateRowsInTable:(NSString *_Nonnull)tableName
               onProperty:(NSString *_Nonnull)property
            propertyValue:(id _Nonnull)propertyValue
               withObject:(id _Nonnull)object
            andConditions:(NSArray<HMDStoreCondition *> * _Nullable)andConditions
             orConditions:(NSArray<HMDStoreCondition *> * _Nullable)orConditions;

- (BOOL)updateRowsInTable:(NSString *_Nonnull)tableName
          checkIvarChange:(BOOL)checkIvarChange
               onProperty:(NSString *_Nonnull)property
            propertyValue:(id _Nonnull)propertyValue
               withObject:(id _Nonnull)object
            andConditions:(NSArray<HMDStoreCondition *> *_Nonnull)andConditions
             orConditions:(NSArray<HMDStoreCondition *> * _Nullable)orConditions;

- (BOOL)updateRowsInTable:(NSString *_Nonnull)tableName
               onProperty:(NSString *_Nonnull)property
            propertyValue:(id _Nonnull)propertyValue
               withObject:(id _Nonnull)object
            andConditions:(NSArray<HMDStoreCondition *> * _Nullable)andConditions
             orConditions:(NSArray<HMDStoreCondition *> * _Nullable)orConditions
                    limit:(NSInteger)limitCount;

- (BOOL)isTableExistsForName:(NSString *_Nonnull)tableName;

//count
- (long long)recordCountForTable:(NSString *_Nonnull)tableName;

- (long long)recordCountForTable:(NSString *_Nonnull)tableName
                   andConditions:(NSArray<HMDStoreCondition *> * _Nullable)andConditions
                    orConditions:(NSArray<HMDStoreCondition *> * _Nullable)orConditions;

//数据库文件大小，单位byte
- (unsigned long long)dbFileSize;

//尝试清理数据库，每次生命周期仅触发一次
- (void)vacuumIfNeeded;

// 用户主动触发清理数据库，不限次数
- (void)immediatelyActiveVacuum;

// perfrom DB checkpoint to truncate wal-file
- (void)executeCheckpoint;

//事务操作
-(void)inTransaction:(BOOL (^_Nonnull)(void))block;

-(void)closeDB;

- (NSInteger)deleteErrorCode;

@end
