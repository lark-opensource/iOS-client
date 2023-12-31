//
//  IESEffectBaseDownloadTask.h
//  EffectPlatformSDK
//
//  Created by zhangchengtao on 2020/3/9.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <EffectPlatformSDK/IESManifestManager.h>
#import <EffectPlatformSDK/IESFileDownloader.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESEffectBaseDownloadTask : NSObject

@property (nonatomic, copy, readonly) NSString *fileMD5;

@property (nonatomic, copy, readonly) NSString *destination;

@property (nonatomic, strong, readonly) NSMutableArray *progressBlocks;

@property (nonatomic, strong, readonly) NSMutableArray *completionBlocks;

@property (nonatomic, strong) IESManifestManager *manifestManager;

@property (nonatomic, assign) NSOperationQueuePriority queuePriority;
@property (nonatomic, assign) NSQualityOfService qualityOfService;

- (instancetype)initWithFileMD5:(NSString *)fileMD5 destination:(NSString *)destination;

- (instancetype)init NS_UNAVAILABLE;

- (void)startWithCompletion:(void (^)(void))completion;

- (void)callProgressBlocks:(CGFloat)progress;

- (void)callCompletionBlocks:(BOOL)success error:(NSError * _Nullable)error traceLog:(NSString *)traceLog;

- (void)downloadFileWithURLs:(NSArray<NSString *> *)urls
                downloadPath:(NSString *)path
            downloadProgress:(IESFileDownloaderProgress)downloadProgress
                  completion:(IESFileDownloaderCompletion)completion;

@end

NS_ASSUME_NONNULL_END
