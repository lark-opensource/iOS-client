//
//  BDAutoTrackDatabaseService.h
//  RangersAppLog
//
//  Created by bob on 2019/9/14.
//

#import "BDAutoTrackService.h"

NS_ASSUME_NONNULL_BEGIN
@class BDAutoTrackBaseTable;

/// path:[BDAutoTrackUtility trackerDocumentPath]
///    - {$appid}/bytedance_auto_track.sqlite
@interface BDAutoTrackDatabaseService : BDAutoTrackService

- (instancetype)initWithAppID:(NSString *)appID;

- (void)clearDatabase;

/********************** 埋点出库 **********************/
- (NSDictionary<NSString *, NSArray *> *)allTracksForBatchReport:(nullable NSDictionary *)options;
- (NSArray<NSDictionary *> *)profileTracks;

/********************** 埋点入库 **********************/
- (void)insertTable:(NSString *)tableName
              track:(NSDictionary *)track
            trackID:(nullable NSString *)trackID
            options:(nullable NSDictionary *)options;

/********************** 将埋点从DB中删除 **********************/
- (void)removeTracks:(NSDictionary<NSString *, NSArray *> *)trackIDs;

//降级priority=0
- (void)downgradeTracks:(NSDictionary<NSString *, NSArray *> *)trackIDs;

/********************** 其它数据库查询 **********************/
- (NSArray<NSString *> *)allTableNames;

- (BDAutoTrackBaseTable *)ceateTableWithName:(NSString *)tableName;

/********************** 数据库vacuum **********************/
- (void)vacuumDatabase;

- (NSUInteger)count;

@end

FOUNDATION_EXTERN BDAutoTrackDatabaseService * _Nullable bd_databaseServiceForAppID(NSString *appID);


FOUNDATION_EXTERN void bd_databaseInsertTrack(NSString *tableName,
                                              NSDictionary *track,
                                              NSString *_Nullable trackID,
                                              NSString *appID,
                                              NSDictionary *_Nullable options);

FOUNDATION_EXTERN void bd_databaseRemoveTracks(NSDictionary<NSString *, NSArray *> *trackIDs,
                                               NSString *appID);

FOUNDATION_EXTERN void bd_databaseDowngradeTracks(NSDictionary<NSString *, NSArray *> *trackIDs,
                                               NSString *appID);

/// for unit test
FOUNDATION_EXTERN BDAutoTrackBaseTable * bd_databaseCeateTable(NSString *tableName, NSString *appID);

FOUNDATION_EXTERN NSString * bd_databaseFilePath(void); /// old database file
FOUNDATION_EXTERN NSString *bd_databaseFilePathForAppID(NSString *appID);

NS_ASSUME_NONNULL_END
