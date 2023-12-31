//
//  AWEStickerDownloadManager.h
//  CameraClient
//
//  Created by zhangchengtao on 2020/4/24.
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/IESEffectModel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AWEStickerDownloadObserverProtocol;

// 道具下载管理
@interface AWEStickerDownloadManager : NSObject

+ (instancetype)manager;

- (void)addObserver:(id<AWEStickerDownloadObserverProtocol>)observer;

- (void)removeObserver:(id<AWEStickerDownloadObserverProtocol>)observer;

- (void)downloadStickerIfNeed:(IESEffectModel *)sticker;

- (nullable NSNumber *)stickerDownloadProgress:(IESEffectModel *)sticker;

- (void)updatePropCellDownloaded:(IESEffectModel *)sticker;

@end

@protocol AWEStickerDownloadObserverProtocol  <NSObject>

@optional

- (void)stickerDownloadManager:(AWEStickerDownloadManager *)manager didBeginDownloadSticker:(IESEffectModel *)sticker;

- (void)stickerDownloadManager:(AWEStickerDownloadManager *)manager sticker:(IESEffectModel *)sticker downloadProgressChange:(CGFloat)progress;

- (void)stickerDownloadManager:(AWEStickerDownloadManager *)manager didFinishDownloadSticker:(IESEffectModel *)sticker;

- (void)stickerDownloadManager:(AWEStickerDownloadManager *)manager didFailDownloadSticker:(IESEffectModel *)sticker withError:(NSError *)error;

- (void)stickerDownloadManager:(AWEStickerDownloadManager *)manager needUpdateCellDownloadedSticker:(IESEffectModel *)sticker;

@end

NS_ASSUME_NONNULL_END
