//
//  AWEStickerPickerSearchBarConfig.m
//  CameraClient-Pods-Aweme
//
//  Created by Syenny on 2021/5/31.
//

#import "AWEStickerPickerSearchBarConfig.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>

@implementation AWEStickerPickerSearchBarConfig

+ (instancetype)sharedConfig {
    static AWEStickerPickerSearchBarConfig *_sharedConfig = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedConfig = [[self alloc] init];
    });

    return _sharedConfig;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _backgroundColor = ACCResourceColor(ACCUIColorBGContainer);
        _tintColor = ACCUIColorFromRGBA(0xFACE15, 1.0);
        _textColor = ACCResourceColor(ACCUIColorTextPrimary);
        _searchFiledBackgroundColor = ACCResourceColor(ACCUIColorConstBGContainerInverse);
        _lensImage = [UIImage acc_imageWithName:@"ic_prop_search_bar_light"];
        _clearImage = [UIImage acc_imageWithName:@"ic_search_bar_clear_white"];
        _searchBarHeight = 48;
        _lensImageTintColor = ACCResourceColor(ACCUIColorIconSecondary);
    }
    return self;
}

@end
