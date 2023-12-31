//Copyright © 2021 Bytedance. All rights reserved.

#import "AWEVideoStickerSavePhotoInfo.h"

@implementation AWEVideoStickerSavePhotoInfo

- (NSString *)toastText
{
    if (!_toastText) {
        _toastText = @"";
    }
    return _toastText;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"photoNames" : @"photoNames",
        @"toastText" : @"toastText",
        @"waterMarkPath" : @"waterMarkPath",
    };
}

- (id)copyWithZone:(NSZone *)zone
{
    AWEVideoStickerSavePhotoInfo *copy = [[AWEVideoStickerSavePhotoInfo alloc] init];
    copy.toastText = self.toastText;
    copy.photoNames = self.photoNames;
    return copy;
}

@end
