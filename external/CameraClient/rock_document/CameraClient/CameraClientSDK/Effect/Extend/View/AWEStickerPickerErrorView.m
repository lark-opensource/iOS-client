//
//  AWEStickerPickerErrorView.m
//  CameraClient
//
//  Created by zhangchengtao on 2020/4/26.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEStickerPickerErrorView.h"
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

@interface AWEStickerPickerErrorView ()

@property (nonatomic, strong, readwrite) UIButton *reloadButton;

@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation AWEStickerPickerErrorView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = ACCLocalizedString(@"error_retry", @"网络不给力，请点击重试");
        _titleLabel.numberOfLines = 0;
        _titleLabel.preferredMaxLayoutWidth = UIScreen.mainScreen.bounds.size.width - 2 * 12.f;
        _titleLabel.font = [ACCFont() systemFontOfSize:15];
        _titleLabel.textColor = ACCResourceColor(ACCUIColorBGContainer7);
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_titleLabel];
        ACCMasMaker(_titleLabel, {
            make.centerX.equalTo(self);
            make.centerY.equalTo(self);
        });
        
        _reloadButton = [[UIButton alloc] init];
        _reloadButton.backgroundColor = [UIColor clearColor];
        [self addSubview:_reloadButton];
        ACCMasMaker(_reloadButton, {
            make.edges.equalTo(@(0));
        });
        
        [_reloadButton addTarget:self action:@selector(onReload) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)onReload {
    if (self.reloadHanlder) {
        self.reloadHanlder();
    }
}

@end
