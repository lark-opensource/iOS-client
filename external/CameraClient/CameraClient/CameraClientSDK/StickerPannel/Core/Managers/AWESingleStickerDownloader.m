//
//  AWESingleStickerDownloader.m
//  Pods
//
//  Created by liyingpeng on 2020/8/4.
//

#import "AWESingleStickerDownloader.h"
#import <EffectPlatformSDK/EffectPlatform.h>
#import <CreativeKit/ACCMacros.h>

@implementation AWESingleStickerDownloadResult

- (BOOL)failed {
    return self.error || ACC_isEmptyString(self.filePath);
}

@end

@implementation AWESingleStickerDownloadInfo

@end

@implementation AWESingleStickerDownloadParameter

@end

@interface AWESingleStickerDownloader ()

@property (nonatomic, strong) AWESingleStickerDownloadParameter *lastDownloadParam;

@end

@implementation AWESingleStickerDownloader

- (void)downloadSticker:(AWESingleStickerDownloadParameter *)downloadParam {
    if (downloadParam.sticker.effectIdentifier.length <= 0) {
        return;
    }
    if (downloadParam.sticker.downloaded) {
        return;
    }
    if (self.lastDownloadParam && [downloadParam.sticker.effectIdentifier isEqualToString:self.lastDownloadParam.sticker.effectIdentifier]) {
        return;
    }
    self.lastDownloadParam.cancelled = YES; // cancel last download。
    self.lastDownloadParam = downloadParam;
    ACCBLOCK_INVOKE(downloadParam.downloadProgressBlock, 0);
    CFTimeInterval singleStickerStartTime = CFAbsoluteTimeGetCurrent();
    @weakify(self);
    [EffectPlatform downloadEffect:downloadParam.sticker progress:^(CGFloat progress){
        ACCBLOCK_INVOKE(downloadParam.downloadProgressBlock, progress);
    } completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
        @strongify(self);
        if ([downloadParam.sticker.effectIdentifier isEqualToString:self.lastDownloadParam.sticker.effectIdentifier]) {
            self.lastDownloadParam = nil;
        }
        if (downloadParam.cancelled) {
            return;
        }
        NSInteger duration = (CFAbsoluteTimeGetCurrent() - singleStickerStartTime) * 1000;
        
        AWESingleStickerDownloadResult *result = [AWESingleStickerDownloadResult new];
        result.error = error;
        result.filePath = filePath;
        
        AWESingleStickerDownloadInfo *info = [AWESingleStickerDownloadInfo new];
        info.result = result;
        info.duration = duration;
        info.effectIdentifier = downloadParam.sticker.effectIdentifier;
        info.fileDownloadURLs = downloadParam.sticker.fileDownloadURLs;
        info.effectName = downloadParam.sticker.effectName;
        ACCBLOCK_INVOKE(downloadParam.compeletion, info);
    }];
}

@end
