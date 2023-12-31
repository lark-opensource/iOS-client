//
//  AWECustomStickerLimitConfig.m
//  CameraClient
//
//  Created by 卜旭阳 on 2020/6/16.
//

#import "AWECustomStickerLimitConfig.h"

@implementation AWECustomStickerLimitConfig

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"gifSizeLimit" : @"upload_image_max",
             @"gifMaxLimit" : @"upload_image_uncompressed_max",
             @"uploadWidthLimit" : @"image_input_width",
             @"uploadHeightLimit" : @"image_input_height",
             };
}

- (CGFloat)gifSizeLimit
{
    if(_gifSizeLimit <= 0) {
        return 3.f;
    }
    return _gifSizeLimit;
}

- (CGFloat)gifMaxLimit
{
    if(_gifMaxLimit <= 0) {
        return 10.f;
    }
    return _gifMaxLimit;
}

- (CGFloat)uploadHeightLimit
{
    if(_uploadHeightLimit <= 0) {
        return 1280.f;
    }
    return _uploadHeightLimit;
}

- (CGFloat)uploadWidthLimit
{
    if(_uploadWidthLimit <= 0) {
        return 720.f;
    }
    return _uploadWidthLimit;
}

@end
