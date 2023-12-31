//
//  ACCLyricsStickerHandler.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/5/6.
//

#import "ACCLyricsStickerHandler.h"

@implementation ACCLyricsStickerHandler

- (BOOL)canExpressSticker:(ACCEditorStickerConfig *)stickerConfig
{
    return [stickerConfig isKindOfClass:[ACCEditorLyricsStickerConfig class]];
}

- (void)expressSticker:(ACCEditorStickerConfig *)stickerConfig
{
    [self expressSticker:stickerConfig withCompletion:^{
        
    }];
}

- (void)expressSticker:(ACCEditorStickerConfig *)stickerConfig withCompletion:(void (^)(void))completionHandler
{
    if ([self canExpressSticker:stickerConfig]) {
        if (self.onExpressLyricsSticker) {
            self.onExpressLyricsSticker((ACCEditorLyricsStickerConfig *)stickerConfig);
        }
    }
}

@end
