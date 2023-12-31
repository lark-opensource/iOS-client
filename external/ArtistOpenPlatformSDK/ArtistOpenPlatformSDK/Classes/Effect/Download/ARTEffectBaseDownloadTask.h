//
//  ARTEffectBaseDownloadTask.h
//  ArtistOpenPlatformSDK
//
//  Created by wuweixin on 2020/10/20.
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/IESFileDownloader.h>

@class ARTManifestManager;

NS_ASSUME_NONNULL_BEGIN

@interface ARTEffectBaseDownloadTask : NSObject
@property (nonatomic, copy, readonly) NSString *fileMD5;

@property (nonatomic, copy, readonly) NSString *destination;

@property (nonatomic, strong, readonly) NSMutableArray *progressBlocks;

@property (nonatomic, strong, readonly) NSMutableArray *completionBlocks;
@property (nonatomic, strong) ARTManifestManager *manifestManager;

- (instancetype)initWithFileMD5:(NSString *)fileMD5 destination:(NSString *)destination;

- (instancetype)init NS_UNAVAILABLE;

- (void)startWithCompletion:(void (^)(void))completion;

- (void)callProgressBlocks:(CGFloat)progress;

- (void)callCompletionBlocks:(BOOL)success error:(NSError * _Nullable)error;

- (void)downloadFileWithURLs:(NSArray<NSString *> *)urls
                downloadPath:(NSString *)path
            downloadProgress:(IESFileDownloaderProgress)downloadProgress
                  completion:(IESFileDownloaderCompletion)completion;
@end

NS_ASSUME_NONNULL_END
