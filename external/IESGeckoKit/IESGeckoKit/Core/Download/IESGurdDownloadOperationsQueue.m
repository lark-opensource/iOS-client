//
//  IESGurdDownloadOperationsQueue.m
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/11/23.
//

#import "IESGurdDownloadOperationsQueue.h"

#import "IESGurdKit+BackgroundDownload.h"
#import "IESGeckoDefines+Private.h"
#import "IESGurdProtocolDefines.h"
#import "IESGurdDelegateDispatcherManager.h"
#import "IESGurdEventTraceManager+Business.h"
#import "IESGurdEventTraceManager+Message.h"

#import "IESGurdKit+Experiment.h"

typedef NSMutableDictionary<NSNumber *, NSMutableArray<IESGurdBaseDownloadOperation *> *> IESGurdDownloadOperationsDictionary;

@interface IESGurdDownloadOperationsQueue ()

@property (nonatomic, strong) IESGurdDownloadOperationsDictionary *operationsDictionary;

@property (nonatomic, strong) NSMutableDictionary<NSString *, IESGurdBaseDownloadOperation *> *fastOperationsDictionary;

@end

@implementation IESGurdDownloadOperationsQueue

#pragma mark - Public

+ (instancetype)operationsQueue
{
    return [[self alloc] init];
}

- (void)addOperation:(IESGurdBaseDownloadOperation *)operation
{
    IESGurdResourceModel *config = operation.config;
    IESGurdDownloadPriority downloadPriority = config.downloadPriority;
    if (![self validateDownloadPriority:downloadPriority]) {
        return;
    }
    
    @synchronized (self) {
        IESGurdDownloadOperationsDictionary *operationsDictionary = self.operationsDictionary;
        if (!operationsDictionary) {
            operationsDictionary = [NSMutableDictionary dictionary];
            self.operationsDictionary = operationsDictionary;
        }
        [self innerAddOperation:operation];
        
        if (!self.fastOperationsDictionary) {
            self.fastOperationsDictionary = [NSMutableDictionary dictionary];
        }
        NSString *operationKey = [self operationKeyWithOperation:operation];
        self.fastOperationsDictionary[operationKey] = operation;
    }
    
    NSString *message = [NSString stringWithFormat:@"Enqueue download %@ package operation (priority : %zd)",
                         [operation isPatch] ? @"patch" : @"full", downloadPriority];
    IESGurdTraceMessageInfo *messageInfo = [IESGurdTraceMessageInfo messageInfoWithAccessKey:config.accessKey
                                                                                     channel:config.channel
                                                                                     message:message
                                                                                    hasError:NO];
    [IESGurdEventTraceManager traceEventWithMessageInfo:messageInfo];
    
    [DELEGATE_DISPATCHER(IESGurdEventDelegate) gurdDidEnqueueDownloadTaskForModel:config];
}

- (IESGurdBaseDownloadOperation *)popNextOperation
{
    if (!self.enableDownload || !IESGurdKit.enableDownload) {
        return [self popNextForceDownloadOperation];
    }
    @synchronized (self) {
        __block IESGurdBaseDownloadOperation *operation = nil;
        __block NSMutableArray *operations = self.operationsDictionary[@(IESGurdDownloadPriorityUserInteraction)];
        if (operations.count > 0) {
            operation = operations.lastObject;
            [operations removeObject:operation];
            return operation;
        }
        NSArray<NSNumber *> *priorities = @[ @(IESGurdDownloadPriorityHigh),
                                             @(IESGurdDownloadPriorityMedium),
                                             @(IESGurdDownloadPriorityLow) ];
        [priorities enumerateObjectsUsingBlock:^(NSNumber *priority, NSUInteger idx, BOOL *stop) {
            operations = self.operationsDictionary[priority];
            if (operations.count > 0) {
                operation = operations.firstObject;
                [operations removeObject:operation];
                *stop = YES;
            }
        }];
        return operation;
    }
}

- (void)removeOperationWithAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    NSString *operationKey = [self operationKeyWithAccessKey:accessKey channel:channel];
    if (operationKey.length > 0) {
        [self.fastOperationsDictionary removeObjectForKey:operationKey];
    }
}

- (IESGurdBaseDownloadOperation *)operationForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    @synchronized (self) {
        NSString *operationKey = [self operationKeyWithAccessKey:accessKey channel:channel];
        if (operationKey.length > 0) {
            return self.fastOperationsDictionary[operationKey];
        }
        return nil;
    }
}

- (void)updateDownloadPriority:(IESGurdDownloadPriority)downloadPriority operation:(IESGurdBaseDownloadOperation *)operation
{
    if (!operation) {
        return;
    }
    IESGurdDownloadPriority previousPriority = operation.downloadPriority;
    if (previousPriority == downloadPriority) {
        return;
    }
    @synchronized (self) {
        // 从旧队列里移除
        IESGurdDownloadOperationsDictionary *operationsDictionary = self.operationsDictionary;
        NSMutableArray *operations = operationsDictionary[@(previousPriority)];
        [operations removeObject:operation];
        // 更新优先级并添加到新队列
        [operation updateDownloadPriority:downloadPriority];
        [self innerAddOperation:operation];
        
        NSString *message = [NSString stringWithFormat:@"Download operation update priority from %zd to %zd",
                             previousPriority, downloadPriority];
        IESGurdTraceMessageInfo *messageInfo = [IESGurdTraceMessageInfo messageInfoWithAccessKey:operation.accessKey
                                                                                         channel:operation.config.channel
                                                                                         message:message
                                                                                        hasError:NO];
        messageInfo.shouldLog = YES;
        [IESGurdEventTraceManager traceEventWithMessageInfo:messageInfo];
    }
}

- (NSDictionary<NSNumber *, NSArray<IESGurdResourceModel *> *> *)allDownloadModels
{
    @synchronized (self) {
        NSMutableDictionary *allDownloadModels = [NSMutableDictionary dictionary];
        [self.operationsDictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, NSMutableArray<IESGurdBaseDownloadOperation *> *obj, BOOL *stop) {
            NSMutableArray *models = [NSMutableArray array];
            for (IESGurdBaseDownloadOperation *operation in obj) {
                if (operation.config) {
                    [models addObject:operation.config];
                }
            }
            allDownloadModels[key] = [models copy];
        }];
        return [allDownloadModels copy];
    }
}

- (void)cancelDownloadWithAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    @synchronized (self) {
        [self.operationsDictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, NSMutableArray<IESGurdBaseDownloadOperation *> *operations, BOOL *stop) {
            __block IESGurdBaseDownloadOperation *targetOperation = nil;
            [operations enumerateObjectsUsingBlock:^(IESGurdBaseDownloadOperation *obj, NSUInteger idx, BOOL *stop) {
                if ([obj.accessKey isEqualToString:accessKey] && [obj.config.channel isEqualToString:channel]) {
                    targetOperation = obj;
                    *stop = YES;
                }
            }];
            if (targetOperation) {
                GurdLog(@"Remove download operation (%@-%@)", accessKey, channel);
                [targetOperation cancel];
                [operations removeObject:targetOperation];
                *stop = YES;
            }
        }];
        [self removeOperationWithAccessKey:accessKey channel:channel];
    }
}

#pragma mark - Private

- (IESGurdBaseDownloadOperation *)popNextForceDownloadOperation
{
    @synchronized (self) {
        __block IESGurdBaseDownloadOperation *operation = nil;
        
        __block NSMutableArray *operations = self.operationsDictionary[@(IESGurdDownloadPriorityUserInteraction)];
        operation = [self popNextForceDownloadOperationInOperations:operations options:NSEnumerationReverse]; // Last In First Out
        if (operation) {
            [operations removeObject:operation];
            return operation;
        }
        
        NSArray<NSNumber *> *priorities = @[ @(IESGurdDownloadPriorityHigh),
                                             @(IESGurdDownloadPriorityMedium),
                                             @(IESGurdDownloadPriorityLow) ];
        [priorities enumerateObjectsUsingBlock:^(NSNumber *priority, NSUInteger idx, BOOL *stop) {
            operations = self.operationsDictionary[priority];
            operation = [self popNextForceDownloadOperationInOperations:operations options:0]; // Fist In First Out
            if (operation) {
                [operations removeObject:operation];
                *stop = YES;
            }
        }];
        return operation;
    }
}

- (IESGurdBaseDownloadOperation *)popNextForceDownloadOperationInOperations:(NSMutableArray<IESGurdBaseDownloadOperation *> *)operations
                                                                    options:(NSEnumerationOptions)options
{
    __block IESGurdBaseDownloadOperation *operation = nil;
    NSArray<NSString *> *accessKeys = IESGurdKit.backgroundAccessKeys;
    [operations enumerateObjectsWithOptions:options usingBlock:^(IESGurdBaseDownloadOperation *obj, NSUInteger idx, BOOL *stop) {
        // 在IESGurdKit.enableDownload为YES的时候，因为后台下载只针对某些特定的ak，需要判断当前下载任务的ak是否属于后台下载的ak
        if ([accessKeys containsObject:obj.accessKey] || !IESGurdKit.enableDownload) {
            if (!obj.config.forceDownload) {
                return;
            }
        }
        operation = obj;
        *stop = YES;
    }];
    return operation;
}

- (BOOL)validateDownloadPriority:(IESGurdDownloadPriority)priority
{
    if (priority < 0) {
        return NO;
    }
    return (priority <= IESGurdDownloadPriorityUserInteraction);
}

- (void)innerAddOperation:(IESGurdBaseDownloadOperation *)operation
{
    IESGurdDownloadPriority downloadPriority = operation.downloadPriority;
    NSMutableArray<IESGurdBaseDownloadOperation *> *operations = self.operationsDictionary[@(downloadPriority)];
    if (!operations) {
        operations = [NSMutableArray array];
        self.operationsDictionary[@(downloadPriority)] = operations;
    }
    [operations addObject:operation];
}

- (NSString *)operationKeyWithOperation:(IESGurdBaseDownloadOperation *)operation
{
    if (!operation) {
        return @"";
    }
    return [self operationKeyWithAccessKey:operation.accessKey channel:operation.config.channel];
}

- (NSString *)operationKeyWithAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    return [NSString stringWithFormat:@"%@-%@", accessKey ? : @"", channel ? : @""];
}

@end
