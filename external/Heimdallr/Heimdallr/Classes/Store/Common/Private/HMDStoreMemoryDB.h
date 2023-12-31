//
//	HMDStoreMemoryDB.h
// 	Heimdallr
// 	
// 	Created by Hayden on 2021/1/14. 
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDStoreMemoryDB : NSObject

// insert
- (BOOL)insertObjects:(NSArray<id> *)objects
                 into:(NSString *)tableName
                appID:(NSString *)appID;

// query
- (NSArray<id> *_Nullable)getAllObjectsWithTableName:(NSString *)tableName
                                               appID:(NSString *)appID;

- (NSArray<id> *_Nullable)getObjectsWithTableName:(NSString *)tableName
                                            appID:(NSString *)appID
                                            limit:(NSInteger)limitCount;

// delete
- (void)deleteAllObjectsFromTable:(NSString *)tableName
                            appID:(NSString *)appID;

- (void)deleteObjectsFromTable:(NSString *)tableName
                         appID:(NSString *)appID
                         count:(NSInteger)count;

// count
- (NSInteger)recordCountForTable:(NSString *)tableName
                           appID:(NSString *)appID;

@end

NS_ASSUME_NONNULL_END
