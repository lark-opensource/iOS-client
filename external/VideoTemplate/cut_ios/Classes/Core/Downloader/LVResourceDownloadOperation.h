//
//  LVResourceDownloadOperation.h
//  LVResourceDownloader
//
//  Created by xiongzhuang on 2019/8/19.
//

#import <Foundation/Foundation.h>
#import "LVDownloadDefinition.h"

NS_ASSUME_NONNULL_BEGIN

/**
 素材下载的回调

 @param error 错误信息
 */
typedef void (^LVResourceDownloadOperationCompletion) (NSString *operationID, NSError *error);

@interface LVResourceDownloadOperation : NSOperation

- (instancetype)initWithCompletion:(LVResourceDownloadOperationCompletion)completion;

/**
 完成的回调
 */
@property (nonatomic, copy, readonly) LVResourceDownloadOperationCompletion completion;


/**
 任务唯一标识
 */
@property (nonatomic, copy) NSString *operationID;


/**
 完成任务

 @param error 错误信息
 */
- (void)finishWithError:(NSError * _Nullable)error;


/**
 取消任务

 @return 成功失败
 */
- (BOOL)handleCanceledIfNeeded;

@end

NS_ASSUME_NONNULL_END
