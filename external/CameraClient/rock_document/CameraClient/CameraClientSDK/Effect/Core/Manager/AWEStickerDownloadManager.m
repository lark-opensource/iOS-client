//
//  AWEStickerDownloadManager.m
//  CameraClient
//
//  Created by zhangchengtao on 2020/4/24.
//

#import "AWEStickerDownloadManager.h"
#import <CreationKitArch/ACCMusicModelProtocol.h>
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <CameraClient/AWEStickerMusicManager+Local.h>
#import <CameraClient/ACCMusicNetServiceProtocol.h>
#import <CameraClient/ACCVideoMusicProtocol.h>
#import <CameraClient/AWEStickerPickerLogMarcos.h>
#import <EffectPlatformSDK/EffectPlatform.h>

// 资源下载结果回调block
typedef void(^awe_sticker_download_completion_t)(BOOL success, NSError * _Nullable error);

@interface AWEStickerDownloadManager ()

@property (nonatomic, strong) NSHashTable<id<AWEStickerDownloadObserverProtocol>> *observers;

@property (nonatomic, strong) NSCache<NSString *, NSNumber *> *stickerDownloadProgressCache;

@end

@implementation AWEStickerDownloadManager

+ (instancetype)manager {
    static AWEStickerDownloadManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        _observers = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory capacity:0];
        _stickerDownloadProgressCache = [[NSCache alloc] init];
    }
    return self;
}

- (void)addObserver:(id<AWEStickerDownloadObserverProtocol>)observer  {
    @synchronized (self.observers) {
        if (observer) {
            [self.observers addObject:observer];
        }
    }
}

- (void)removeObserver:(id<AWEStickerDownloadObserverProtocol>)observer {
    @synchronized (self.observers) {
        if (observer && [self.observers containsObject:observer]) {
            [self.observers removeObject:observer];
        }
    }
}

- (void)downloadStickerIfNeed:(IESEffectModel *)sticker {
    if (!sticker.md5) {
        return;
    }
    
    // 已下载
    if (sticker.downloaded && ![sticker acc_isForceBindingMusic]) {
        return;
    }
    
    NSNumber *progress = [self.stickerDownloadProgressCache objectForKey:sticker.md5];
    if (progress != nil) {
        // 正在下载
        return;
    }
    
    // 标记进度为0
    progress = @(0);
    [self.stickerDownloadProgressCache setObject:progress forKey:sticker.md5];
    
    // 通知开始下载
    [self notifyObserversDidBeginDownloadSticker:sticker];
    
    // 下载强绑定音乐和道具资源
    [self p_downloadBindingMusicIfNeeded:sticker completion:^(BOOL success, NSError * _Nullable error) {
        if (error) {
            AWEStickerPickerLogError(@"download binding music failed, effect id=%@|error=%@", sticker.effectIdentifier, error);
        }
        [self p_downloadSticker:sticker];
    }];
}

- (void)updatePropCellDownloaded:(IESEffectModel *)sticker
{
    [self notifyObserversNeedUpdateCellDownloadedSticker:sticker];
}

/**
 * 下载道具资源
 */
- (void)p_downloadSticker:(IESEffectModel *)sticker {
    [EffectPlatform downloadEffect:sticker
             downloadQueuePriority:NSOperationQueuePriorityNormal
          downloadQualityOfService:NSQualityOfServiceDefault
                          progress:^(CGFloat progress) {
        [self.stickerDownloadProgressCache setObject:@(progress) forKey:sticker.md5];
        [self notifyObserversDidChangeProgressWithSticker:sticker progress:progress];
        
    } completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
        [self.stickerDownloadProgressCache removeObjectForKey:sticker.md5];
        if (filePath && !error) {
            // 下载成功
            [self notifyObserversDidFinishDownloadSticker:sticker];
        } else {
            // 下载失败
            [self notifyObserversDidFinishDownloadSticker:sticker error:error];
        }
    }];
}

/**
 * 下载道具强绑定音乐
 */
- (void)p_downloadBindingMusicIfNeeded:(IESEffectModel *)sticker completion:(awe_sticker_download_completion_t)completion {
    if (![sticker acc_isForceBindingMusic]) {
        // 无强绑定音乐或者不需要下载强绑定音乐，则视作成功下载
        if (completion) {
            completion(YES, nil);
        }
        return;
    }
    
    NSString *musicID = sticker.musicIDs.firstObject;
    // 下载音乐model和文件
    [IESAutoInline(ACCBaseServiceProvider(), ACCMusicNetServiceProtocol) requestMusicItemWithID:musicID completion:^(id<ACCMusicModelProtocol> _Nullable model, NSError * _Nullable error) {
        [AWEStickerMusicManager insertMusicModelToCache:model];
        if (model && !error && !model.isOffLine) {
            [ACCVideoMusic() fetchLocalURLForMusic:model withProgress:nil completion:^(NSURL * _Nonnull localURL, NSError * _Nonnull error) {
                if (localURL && !error) {
                    if (completion) {
                        completion(YES, nil);
                    }
                } else {
                    if (completion) {
                        completion(NO, error);
                    }
                }
            }];
        } else {
            if (completion) {
                completion(NO, error);
            }
        }
    }];
}

- (nullable NSNumber *)stickerDownloadProgress:(IESEffectModel *)sticker {
    if (!sticker.md5) {
        return nil;
    }
    
    return [self.stickerDownloadProgressCache objectForKey:sticker.md5];
}

#pragma mark - notify

- (void)notifyObserversDidBeginDownloadSticker:(IESEffectModel *)sticker {
    @synchronized (self.observers) {
        [self.observers.allObjects enumerateObjectsUsingBlock:^(id<AWEStickerDownloadObserverProtocol>  _Nonnull observer, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([observer respondsToSelector:@selector(stickerDownloadManager:didBeginDownloadSticker:)]) {
                [observer stickerDownloadManager:self didBeginDownloadSticker:sticker];
            }
        }];
    }
}

- (void)notifyObserversDidChangeProgressWithSticker:(IESEffectModel *)sticker progress:(CGFloat)progress {
    @synchronized (self.observers) {
        [self.observers.allObjects enumerateObjectsUsingBlock:^(id<AWEStickerDownloadObserverProtocol>  _Nonnull observer, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([observer respondsToSelector:@selector(stickerDownloadManager:sticker:downloadProgressChange:)]) {
                [observer stickerDownloadManager:self sticker:sticker downloadProgressChange:progress];
            }
        }];
    }
}

- (void)notifyObserversDidFinishDownloadSticker:(IESEffectModel *)sticker {
    @synchronized (self.observers) {
        [self.observers.allObjects enumerateObjectsUsingBlock:^(id<AWEStickerDownloadObserverProtocol>  _Nonnull observer, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([observer respondsToSelector:@selector(stickerDownloadManager:didFinishDownloadSticker:)]) {
                [observer stickerDownloadManager:self didFinishDownloadSticker:sticker];
            }
        }];
    }
}

- (void)notifyObserversDidFinishDownloadSticker:(IESEffectModel *)sticker error:(NSError *)error {
    @synchronized (self.observers) {
        [self.observers.allObjects enumerateObjectsUsingBlock:^(id<AWEStickerDownloadObserverProtocol>  _Nonnull observer, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([observer respondsToSelector:@selector(stickerDownloadManager:didFailDownloadSticker:withError:)]) {
                [observer stickerDownloadManager:self didFailDownloadSticker:sticker withError:error];
            }
        }];
    }
}

- (void)notifyObserversNeedUpdateCellDownloadedSticker:(IESEffectModel *)sticker {
    @synchronized (self.observers) {
        [self.observers.allObjects enumerateObjectsUsingBlock:^(id<AWEStickerDownloadObserverProtocol>  _Nonnull observer, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([observer respondsToSelector:@selector(stickerDownloadManager:needUpdateCellDownloadedSticker:)]) {
                [observer stickerDownloadManager:self needUpdateCellDownloadedSticker:sticker];
            }
        }];
    }
}

@end
