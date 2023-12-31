//
//  TTKitchenSyncer+PersistentConnection.m
//  TTKitchen
//
//  Created by bytedance on 2020/11/5.
//

#import "TTKitchenSyncer+PersistentConnection.h"
#import "TTKitchenSyncerInternal.h"
#import "TTKitchen.h"
#import <TTNetworkManager/TTNetworkManager.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <BDMonitorProtocol/BDMonitorProtocol.h>
#import <objc/runtime.h>

typedef NS_OPTIONS(NSUInteger, TTKitchenByteSyncTaskType) {
    TaskTypeUpdating = 1, // Using syncData to synchronize settings again.
    TaskTypeCovering = 2, // Using syncData to cover TTKitchen local cache.
    TaskTypeVerifedCovering = 3, // First verify, then perform like TaskTypeCovering
};

@interface TTKitchenSyncer ()

@property (atomic, strong) NSMutableDictionary <NSString *, NSString *> *updatingTypeTaskData;
@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, strong) NSLock *dataLock;
@property (nonatomic, copy) NSDictionary *netCommomParams;

@end

@implementation TTKitchenSyncer (PersistentConnection)

- (void)resynchronizeSettingsWithTaskParams:(NSDictionary *)taskParams{
    if (self.synchronizing) {
        return;
    }
    self.synchronizing = YES;
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:self.defaultParameters];
    [parameters addEntriesFromDictionary:taskParams];
    [parameters removeObjectForKey:@"ctx_infos"];
    NSString * URLString = self.defaultURLString;
    NSDictionary * header = self.cachedHeader;
    
    NSMutableDictionary *tmpPara = parameters.mutableCopy;
    NSDictionary *finalParameters = tmpPara.copy;
    __auto_type handleResponse = ^(NSDictionary *obj, NSError *error){
        if (!error) {
            if (![obj isKindOfClass:NSDictionary.class]) {
                return;
            }
            NSDictionary *settings = @{};
            if ([obj isKindOfClass:NSDictionary.class]) {
                settings = [[obj btd_dictionaryValueForKey:@"data"] btd_dictionaryValueForKey:@"settings" default:@{}];
            }
            [TTKitchen updateWithDictionary:settings];
            self.synchronizing = NO;
        }
        else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.synchronizing = NO;
                if (self.retryCount > 2) {
                    self.retryCount = 0;
                    return;
                }
                self.retryCount++;
                [self resynchronizeSettingsWithTaskParams:taskParams];
            });
        }
    };
    
    [[TTNetworkManager shareInstance] requestForJSONWithResponse:URLString params:finalParameters method:@"GET" needCommonParams:self.needTTNetCommonParams headerField:header requestSerializer:nil responseSerializer:nil autoResume:YES verifyRequest:YES isCustomizedCookie:NO callback:^(NSError *error, id obj, TTHttpResponse *response) {
        handleResponse(obj, error);
    } callbackInMainThread:NO];
}

- (void)syncData:(nonnull NSData *)data businessID:(int32_t)businessID {
    NSDictionary *jsonDict = [data btd_jsonDictionary];
    if (jsonDict == nil) {
        return;
    }
    
    TTKitchenByteSyncTaskType taskType = [jsonDict btd_intValueForKey:@"task_type"];
    NSNumber *date = [[NSUserDefaults standardUserDefaults] objectForKey:kTTKitchenSynchronizeDate];
    
    if (taskType == TaskTypeVerifedCovering) {
        NSMutableDictionary *infoDict = [self verifyWith:date andCoverData:jsonDict];
        infoDict[@"businessID"] = @(businessID);
        infoDict[@"taskId"] = [jsonDict btd_stringValueForKey:@"task_id"];
        infoDict[@"taskType"] = @(taskType);
        [self reportHmdEvent:[infoDict copy]];
    }
    else {
        NSString * taskId = [jsonDict btd_stringValueForKey:@"task_id"];
        NSString * taskData = [jsonDict btd_stringValueForKey:@"task_data"];
        NSTimeInterval timeStamp = [jsonDict btd_doubleValueForKey:@"time_stamp"];
        
        if (timeStamp < date.doubleValue) {
            return;
        }
        if (taskType == TaskTypeUpdating) {
            [self updateWithTaskId:taskId andData:taskData];
        }
        else if (taskType == TaskTypeCovering) {
            [self coverWithData:taskData];
        }
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[@"businessID"] = @(businessID);
        dict[@"taskId"] = taskId;
        dict[@"taskData"] = taskData;
        dict[@"taskType"] = @(taskType);
        dict[@"time_stamp"] = @(timeStamp);
        [self reportHmdEvent:[dict copy]];
    }
}

- (NSMutableDictionary *)verifyWith:(NSNumber *)date andCoverData:(NSDictionary *)jsonDict {
    NSString *originMD5 = [jsonDict btd_stringValueForKey:@"params_md5"];
    NSMutableDictionary *taskData = [[NSMutableDictionary alloc] initWithDictionary:[[jsonDict btd_stringValueForKey:@"task_data"] btd_jsonDictionary]];
    NSTimeInterval timeStamp = [jsonDict btd_doubleValueForKey:@"time_stamp"];
    NSMutableDictionary *infoDict = [NSMutableDictionary dictionary];
    
    BOOL validParams = originMD5 && self.commonParametersStr && [originMD5 isEqualToString:[self.commonParametersStr btd_md5String]];
    BOOL validTime = timeStamp > date.doubleValue;
    
    if (validParams && validTime) {
        /// Delete keys in __null field
        NSArray *nullKeys = [taskData btd_arrayValueForKey:@"__null"];
        if (nullKeys) {
            NSMutableArray *invalidKeys = [NSMutableArray array];
            [nullKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL * _Nonnull stop) {
                if (![TTKitchen removeCacheWithKey:key]) {
                    [invalidKeys addObject:key];
                }
            }];
            [taskData removeObjectForKey:@"__null"];
            if ([invalidKeys count]) {
                infoDict[@"not_existed_null_keys"] = invalidKeys;
            }
        }
        /// Cover data
        [TTKitchen updateWithDictionary:taskData];
    }
    
    infoDict[@"time_stamp"] = @(timeStamp);
    infoDict[@"task_data"] = taskData;
    infoDict[@"valid_params"] = validParams ? @1 : @0;
    infoDict[@"valid_time"] = validTime ? @1 : @0;
    
    return infoDict;
}

- (void)updateWithTaskId:(NSString *)taskId andData:(NSString *)taskData {
    if ([self.lock tryLock]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self _addUpdatingTypeTaskData:taskData forTaskId:taskId];
            sleep(self.waitTime);
            [self.dataLock lock];
            if ([self.updatingTypeTaskData.allKeys count] != 0) {
                NSDictionary *taskParams = @{
                    @"pull_task_ids" : [self.updatingTypeTaskData.allKeys componentsJoinedByString:@","],
                    @"pull_task_data" : [self.updatingTypeTaskData.allValues componentsJoinedByString:@","]
                };
                [[TTKitchenSyncer sharedInstance] resynchronizeSettingsWithTaskParams:taskParams];
            }
            [self.updatingTypeTaskData removeAllObjects];
            [self.dataLock unlock];
            [self.lock unlock];
        });
    }
    else {
        [self _addUpdatingTypeTaskData:taskData forTaskId:taskId];
    }
}

- (void)coverWithData:(NSString *)taskData {
    NSDictionary * coveringData = [taskData btd_jsonDictionary];
    [TTKitchen updateWithDictionary:coveringData];
}

- (void)reportHmdEvent:(NSDictionary *)info {
    [BDMonitorProtocol hmdTrackService:@"kitchen_bytesync_data" metric:@{} category:info extra:@{}];
}

- (void)setWaitTime:(NSTimeInterval)waitTime {
    objc_setAssociatedObject(self, @selector(waitTime), @(waitTime), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSTimeInterval)waitTime {
    NSNumber * waitTime = objc_getAssociatedObject(self, _cmd);
    if (waitTime) {
        return [waitTime doubleValue];
    }
    return 5.0;
}

- (void)setCommonParametersStr:(NSString *)commonParametersStr {
    objc_setAssociatedObject(self, @selector(commonParametersStr), commonParametersStr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)commonParametersStr {
    return objc_getAssociatedObject(self, @selector(commonParametersStr));
}

- (void)setUpdatingTypeTaskData:(NSMutableDictionary<NSString *,NSString *> *)updatingTypeTaskData {
    objc_setAssociatedObject(self, @selector(updatingTypeTaskData), updatingTypeTaskData, OBJC_ASSOCIATION_RETAIN);
}
- (NSMutableDictionary<NSString *,NSString *> *)updatingTypeTaskData {
    NSMutableDictionary *data = objc_getAssociatedObject(self, _cmd);
    if (data == nil) {
        data = NSMutableDictionary.new;
        [self setUpdatingTypeTaskData:data];
    }
    return data;
}

- (void)setLock:(NSLock *)lock {
    objc_setAssociatedObject(self, @selector(lock), lock, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSLock *)lock{
    NSLock *lock = objc_getAssociatedObject(self, _cmd);
    if (lock == nil) {
        lock = NSLock.new;
        [self setLock:lock];
    }
    return lock;
}

- (void)setDataLock:(NSLock *)dataLock {
    objc_setAssociatedObject(self, @selector(dataLock), dataLock, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSLock *)dataLock {
    NSLock *dataLock = objc_getAssociatedObject(self, _cmd);
    if (dataLock == nil) {
        dataLock = NSLock.new;
        [self setDataLock:dataLock];
    }
    return dataLock;
}

- (void)_addUpdatingTypeTaskData:(NSString *)taskData forTaskId:(NSString *)taskId {
    [self.dataLock lock];
    if (self.updatingTypeTaskData && taskId) {
        [self.updatingTypeTaskData setObject:(taskData ?:@"") forKey:taskId];
    }
    [self.dataLock unlock];
}

@end

