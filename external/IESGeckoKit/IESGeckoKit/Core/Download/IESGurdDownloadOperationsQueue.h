//
//  IESGurdDownloadOperationsQueue.h
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/11/23.
//

#import <Foundation/Foundation.h>

#import "IESGurdBaseDownloadOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdDownloadOperationsQueue : NSObject

@property (atomic, assign) BOOL enableDownload;

+ (instancetype)operationsQueue;

- (void)addOperation:(IESGurdBaseDownloadOperation *)operation;

- (IESGurdBaseDownloadOperation *)popNextOperation;

- (void)removeOperationWithAccessKey:(NSString *)accessKey channel:(NSString *)channel;

- (IESGurdBaseDownloadOperation *)operationForAccessKey:(NSString *)accessKey channel:(NSString *)channel;

- (void)updateDownloadPriority:(IESGurdDownloadPriority)downloadPriority operation:(IESGurdBaseDownloadOperation *)operation;

- (NSDictionary<NSNumber *, NSArray<IESGurdResourceModel *> *> *)allDownloadModels;

- (void)cancelDownloadWithAccessKey:(NSString *)accessKey channel:(NSString *)channel;

@end

NS_ASSUME_NONNULL_END
