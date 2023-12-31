//
//  HMDURLBackgrounSessionManager.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/5/14.
//

#import <Foundation/Foundation.h>

@protocol HMDURLBackgrounSessionManagerDelegate <NSObject>

- (void)URLSession:(nonnull NSURLSession *)session task:(nonnull NSURLSessionTask *)task didCompleteWithResponseObject:(nullable id)responseObject error:(nullable NSError *)error;

@optional
- (void)URLSession:(nullable NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_BEGIN

@interface HMDURLBackgrounSessionManager : NSObject

@property (nonatomic,weak) id<HMDURLBackgrounSessionManagerDelegate> delegate;

- (instancetype)init __deprecated_msg("use initWithDelegate:configuration: instead");

- (instancetype)initWithDelegate:(id<HMDURLBackgrounSessionManagerDelegate>)delegate
                   configuration:(NSURLSessionConfiguration *)configuration;

- (NSURLSessionUploadTask * _Nullable)uploadWithRequest:(NSURLRequest *)request filePath:(NSString *)filePath;

- (void)queryAllUploadTasks:(void(^)(NSArray *tasks))completion;

- (NSArray *)getAllUploadTasks;

@end

NS_ASSUME_NONNULL_END
