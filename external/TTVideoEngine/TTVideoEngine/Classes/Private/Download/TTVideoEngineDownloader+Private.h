//
//  Header.h
//  TTVideoEngine
//
//  Created by 黄清 on 2020/3/22.
//

#ifndef TTVideoEngineDownloader_Private_h
#define TTVideoEngineDownloader_Private_h
#import "TTVideoEngineDownloader.h"


NS_ASSUME_NONNULL_BEGIN
@class TTVideoEngineKVStorage;
@interface TTVideoEngineDownloader ()
@property (nonatomic, assign) int64_t maxTaskId;
@property (nonatomic, strong) NSMutableArray *allTasks;
@property (nonatomic, strong) NSMutableSet *runningTasks;
@property (nonatomic, strong) NSMutableArray *waitingTasks;
@property (nonatomic, strong) TTVideoEngineKVStorage *storage;
@property (nonatomic,   copy) NSString *tasksIndexPath;
@property (nonatomic, strong) NSMutableArray *indexArray;

@property (nonatomic, assign) BOOL readAllTask;
@property (nonatomic, assign) BOOL loadingData;

- (BOOL)shouldResume:(TTVideoEngineDownloadTask *)task;
- (BOOL)suspended:(TTVideoEngineDownloadTask *)task;
- (void)resume:(TTVideoEngineDownloadTask *)task;
- (void)task:(TTVideoEngineDownloadTask *)task completeError:(NSError *_Nullable)error;
- (void)cancelTask:(TTVideoEngineDownloadTask *)task;
- (void)progress:(NSString *)key info:(NSDictionary *)info;
- (void)downloadFail:(NSString *)key error:(NSError *)error;
- (void)downloadDidSuspend:(NSString *)key;
- (void)tryNextWaitingTask:(TTVideoEngineDownloadTask *)nowTask;

@end
NS_ASSUME_NONNULL_END
#endif /* Header_h */
