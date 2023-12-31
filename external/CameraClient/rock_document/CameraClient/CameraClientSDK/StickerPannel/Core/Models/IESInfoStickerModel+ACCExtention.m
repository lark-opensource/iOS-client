//
//  IESInfoStickerModel+ACCExtention.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/2/28.
//

#import "IESInfoStickerModel+ACCExtention.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <objc/runtime.h>

@implementation IESInfoStickerModel(ACCExtention)

- (BOOL)stickerDownloading
{
    return [objc_getAssociatedObject(self, @selector(stickerDownloading)) boolValue];
}

- (void)setStickerDownloading:(BOOL)stickerDownloading
{
    objc_setAssociatedObject(self, @selector(stickerDownloading), @(stickerDownloading), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSArray *)previewImgUrls
{
    NSArray *imgs = objc_getAssociatedObject(self, @selector(previewImgUrls));
    if (!imgs) {
        if (self.dataSource == IESInfoStickerModelSourceLoki) {
            imgs = [self.iconDownloadURLs mutableCopy];
        } else {
            NSMutableArray *images = [[NSMutableArray alloc] init];
            if (self.sticker.url) {
                [images acc_addObject:self.sticker.url];
            }
            if (self.thumbnailSticker.url) {
                [images acc_addObject:self.thumbnailSticker.url];
            }
            imgs = [images copy];
        }
        objc_setAssociatedObject(self, @selector(previewImgUrls), imgs, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    return imgs;
}

@end
