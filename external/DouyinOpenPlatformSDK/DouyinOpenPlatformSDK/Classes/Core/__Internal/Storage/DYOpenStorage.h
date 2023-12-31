//
//  DYOpenDBStorage.h
//  Timor
//
//  Created by gejunchen.ChenJr on 2021/11/9.
//

#import "DYOpenKVInterface.h"

NS_ASSUME_NONNULL_BEGIN

@class FMDatabaseQueue;
@interface DYOpenDBStorage : NSObject <DYOpenKVInterface>

@property(nonatomic, readonly) FMDatabaseQueue *dbQueue;

- (instancetype)initWithStorageID:(NSString *)storageID dbQueue:(nullable FMDatabaseQueue *)dbQueue;

@end

NS_ASSUME_NONNULL_END
