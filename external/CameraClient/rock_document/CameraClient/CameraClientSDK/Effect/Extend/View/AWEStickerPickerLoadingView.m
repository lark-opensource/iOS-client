//
//  AWEStickerPickerLoadingView.m
//  CameraClient
//
//  Created by zhangchengtao on 2020/4/26.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEStickerPickerLoadingView.h"
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/CALayer+AWEStudioAddtions.h>
#import <Masonry/View+MASAdditions.h>

@interface AWEStickerPickerLoadingView ()

@property (nonatomic, strong) UILabel *textLabel;

@property (nonatomic, strong) UIImageView *loadingImageView;

@end

@implementation AWEStickerPickerLoadingView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];

        _textLabel = [[UILabel alloc] init];
        _textLabel.text =  ACCLocalizedString(@"effect_loading_new",@"道具加载中");
        _textLabel.font = [ACCFont() systemFontOfSize:15];
        _textLabel.textColor = ACCResourceColor(ACCUIColorConstTextTertiary3);
        [self addSubview:_textLabel];
        ACCMasMaker(_textLabel, {
            make.centerX.equalTo(self);
            make.centerY.equalTo(self);
        });

        _loadingImageView = [[UIImageView alloc] initWithImage:[ACCResourceImage(@"icon30WhiteSmall") imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        _loadingImageView.tintColor = ACCResourceColor(ACCUIColorConstTextInverse3);
        [self addSubview:_loadingImageView];
        ACCMasMaker(_loadingImageView, {
            make.width.height.equalTo(@15);
            make.centerY.equalTo(_textLabel);
            make.right.equalTo(_textLabel.mas_left).offset(-6);
        });
        
        [_loadingImageView.layer acc_addRotateAnimation];
    }
    return self;
}

@end
