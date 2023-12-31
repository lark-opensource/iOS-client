//
//  TSPKSignalManager+private.h
//  TT
//
//  Created by ByteDance on 2022/11/17.
//

#import "TSPKSignalManager.h"
#import <pthread/pthread.h>

extern NSString * _Nullable const TSPKSignalTimeKey;

@interface TSPKSignalManager ()
{
    pthread_rwlock_t _rwPermissionInfoLock;
    dispatch_queue_t _writeQueue;
}

@property (nonatomic, strong, nullable) NSMutableDictionary <NSString *, NSMutableArray *> * permissionInfo;

- (nullable NSDictionary *)signalWithType:(TSPKSignalType)signalType
                        content:(nonnull NSString*)content
                          extraInfo:(nullable NSDictionary*)extraInfo
                               timestamp:(NSTimeInterval)timestamp;

- (nullable NSString *)signalStringWithType:(TSPKSignalType)type;
- (void)removeObjectsBeforeTimestamp:(NSTimeInterval)timestamp inArray:(nullable NSMutableArray *)array;
- (void)removeFirstObjectIfExceed:(nullable NSMutableArray *)array;

- (BOOL)isEnabled;

@property (nonatomic, copy, readonly, nullable) NSDictionary *logConfig;

- (nullable NSArray *)signalFlowWithPermissionType:(nonnull NSString *)permissionType
                        startTimestamp:(NSTimeInterval)startTimestamp;

- (NSInteger)beforeStartRange;

+ (void)removeAllSignalsWithPermissionType:(nonnull NSString *)permissionType;

- (nullable NSArray *)signalTypesWithPermissionType:(nonnull NSString *)permissionType;

- (nullable NSArray *)signalFlowWithPermissionType:(nonnull NSString *)permissionType
                                    startTimestamp:(NSTimeInterval)startTimestamp
                                    needFormatTime:(BOOL)needFormatTime;
@end
