//
//  BDAutoTrackTables.h
//  RangersAppLog
//
//  Created by bob on 2019/9/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class BDAutoTrackDatabaseQueue;

FOUNDATION_EXTERN NSMutableArray<NSString *> *bd_db_allTableNames(BDAutoTrackDatabaseQueue *databaseQueue);

NS_ASSUME_NONNULL_END
