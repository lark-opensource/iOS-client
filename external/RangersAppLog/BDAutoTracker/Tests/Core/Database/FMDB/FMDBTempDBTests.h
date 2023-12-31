//
//  FMDBTempDBTests.h
//  fmdb
//
//  Created by Graham Dennis on 24/11/2013.
//
//

#import <XCTest/XCTest.h>
#import <RangersAppLog/BDAutoTrackDB.h>
#if FMDB_SQLITE_STANDALONE
#import <sqlite3/sqlite3.h>
#else
#import <sqlite3.h>
#endif

@protocol FMDBTempDBTests <NSObject>

@optional
+ (void)populateDatabase:(BDAutoTrackDatabase *)database;

@end

@interface FMDBTempDBTests : XCTestCase <FMDBTempDBTests>

@property BDAutoTrackDatabase *db;
@property (readonly) NSString *databasePath;

@end
