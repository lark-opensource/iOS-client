//
//  AWECustomPhotoStickerEditConfig.m
//  CameraClient
//
//  Created by 卜旭阳 on 2020/6/22.
//

#import "AWECustomPhotoStickerEditConfig.h"
#import "AWECustomStickerLimitConfig.h"
#import <MobileCoreServices/UTCoreTypes.h>

@interface AWECustomPhotoStickerEditConfig()

@property (nonatomic, assign, readwrite) BOOL isGIF;

@property (nonatomic, assign, readwrite) BOOL shouldUsePNGRepresentation;

@property (nonatomic, strong, readwrite) AWECustomStickerLimitConfig *configs;

@end

@implementation AWECustomPhotoStickerEditConfig

- (instancetype)initWithUTI:(NSString *)dataUTI limit:(AWECustomStickerLimitConfig *)configs
{
    self = [super init];
    if(self) {
        _isGIF = [dataUTI isEqualToString:(id)kUTTypeGIF];
        _shouldUsePNGRepresentation = [dataUTI isEqualToString:(id)kUTTypePNG] || [dataUTI isEqualToString:(id)kUTTypeTIFF] || [dataUTI isEqualToString:(id)kUTTypeAppleICNS] || [dataUTI isEqualToString:(id)kUTTypeICO] || [dataUTI isEqualToString:(id)kUTTypeBMP];
        _configs = configs;
    }
    return self;
}

- (AWECustomStickerLimitConfig *)configs
{
    if(!_configs) {
        _configs = [[AWECustomStickerLimitConfig alloc] init];
    }
    return _configs;
}
@end

@implementation AWECustomPhotoStickerClipedInfo

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"content"      :  @"content",
             @"points"       :  @"contours_point",
             @"bbox"          :  @"bbox"
             };
}

- (CGRect)boxRect
{
    return CGRectMake(((NSNumber *)_bbox[@"x"]).doubleValue,((NSNumber *)_bbox[@"y"]).doubleValue,((NSNumber *)_bbox[@"w"]).doubleValue,((NSNumber *)_bbox[@"h"]).doubleValue);
}

- (BOOL)clipInfoValid
{
    return self.content.length && self.points.firstObject.count && !CGRectEqualToRect(self.boxRect, CGRectZero);
}

@end
