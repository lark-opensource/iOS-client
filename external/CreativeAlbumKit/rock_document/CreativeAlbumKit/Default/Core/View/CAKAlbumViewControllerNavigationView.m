//
//  CAKAlbumViewControllerNavigationView.m
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/6.
//

#import "CAKAlbumViewControllerNavigationView.h"
#import "UIColor+AlbumKit.h"
#import "UIImage+AlbumKit.h"
#import "CAKLanguageManager.h"

#import <CreativeKit/ACCMacros.h>
#import <Masonry/Masonry.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCAccessibilityProtocol.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>

@implementation CAKAlbumViewControllerNavigationView

@synthesize closeButton = _closeButton;

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI
{
    self.backgroundColor = CAKResourceColor(ACCUIColorConstBGContainer);
    
    [self addSubview:self.titleLabel];
    [self addSubview:self.closeButton];
    [self addSubview:self.selectAlbumButton];
    
    ACCMasMaker(self.closeButton, {
        make.left.equalTo(@16);
        make.centerY.equalTo(self.mas_centerY);
    });
    
    ACCMasMaker(self.selectAlbumButton, {
        make.centerX.equalTo(self.mas_centerX);
        make.centerY.equalTo(self.mas_centerY);
        make.width.mas_lessThanOrEqualTo(@143);
    });
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    CGRect frame;
    CGFloat diff = 0;
    frame = self.titleLabel.frame;
    frame.origin.x = (w - frame.size.width) / 2;
    frame.origin.y = (h - frame.size.height) / 2 + diff;
    self.titleLabel.frame = frame;
}

#pragma mark - Getter

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = CAKResourceColor(ACCUIColorConstTextTertiary);
        _titleLabel.font = [ACCFont() acc_boldSystemFontOfSize:17];
        [_titleLabel sizeToFit];
    }
    return _titleLabel;
}

- (CAKAlbumSelectAlbumButton *)selectAlbumButton
{
    if (!_selectAlbumButton) {
        _selectAlbumButton = [[CAKAlbumSelectAlbumButton alloc] initWithType:CAKAnimatedButtonTypeAlpha titleAndImageInterval:4];
        _selectAlbumButton.leftLabel.text = CAKLocalizedString(@"im_all_photos", @"All photos");
        _selectAlbumButton.leftLabel.font = [ACCFont() acc_boldSystemFontOfSize:17];
        _selectAlbumButton.leftLabel.backgroundColor = [UIColor clearColor];
        _selectAlbumButton.leftLabel.textColor = CAKResourceColor(ACCUIColorConstTextPrimary);
        _selectAlbumButton.rightImageView.image = CAKResourceImage(@"icon_mv_arrow_down");
    }
    return _selectAlbumButton;
}

- (UIButton *)closeButton
{
    if (!_closeButton) {
        UIImage *closeImage = CAKResourceImage(@"icon_album_close");
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setImage:closeImage forState:UIControlStateNormal];
        _closeButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-8, -8, -8, -8);
        if ([ACCAccessibility() respondsToSelector:@selector(enableAccessibility:traits:label:)]) {
            [ACCAccessibility() enableAccessibility:_closeButton
                                             traits:UIAccessibilityTraitButton
                                              label:CAKLocalizedString(@"back_confirm", @"Back")];
        }
    }
    return _closeButton;
}

@end
