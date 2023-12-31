//
//  CAKAlbumPreviewPageBottomView.m
//  CreativeAlbumKit-Pods-Aweme
//
//  Created by yuanchang on 2021/1/14.
//

#import "CAKAlbumPreviewPageBottomView.h"
#import "UIImage+AlbumKit.h"
#import "UIImage+CAKUIKit.h"
#import "UIColor+AlbumKit.h"
#import "CAKLanguageManager.h"
#import <Masonry/Masonry.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>

@interface CAKAlbumPreviewPageBottomView ()

@property (nonatomic, assign) CAKAlbumAssetsSelectedIconStyle selectedIconStyle;
@property (nonatomic, assign) BOOL enableRepeatSelect;

@end

@implementation CAKAlbumPreviewPageBottomView

- (instancetype)initWithSelectedIconStyle:(CAKAlbumAssetsSelectedIconStyle)iconStyle enableRepeatSelect:(BOOL)enableRepeatSelect
{
    if (self = [super init]) {
        _selectedIconStyle = iconStyle;
        _enableRepeatSelect = enableRepeatSelect;
        [self p_setupSubviews];
    }
    return self;
}

- (void)p_setupSubviews
{
    self.backgroundColor = [UIColor clearColor];
    
    _nextButton = [[UIButton alloc] init];
    _nextButton.backgroundColor = CAKResourceColor(ACCColorPrimary);
    [_nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_nextButton setTitleColor:CAKResourceColor(ACCColorConstTextInverse) forState:UIControlStateDisabled];
    [_nextButton setTitle:CAKLocalizedString(@"common_next", @"next") forState:UIControlStateNormal];
    _nextButton.titleLabel.font = [ACCFont() acc_systemFontOfSize:14.0f weight:ACCFontWeightMedium];
    _nextButton.titleEdgeInsets = UIEdgeInsetsMake(0, 12, 0, 12);
    _nextButton.layer.cornerRadius = 2.0f;
    _nextButton.clipsToBounds = YES;
    [self addSubview:self.nextButton];

    CGSize sizeFits = [self.nextButton sizeThatFits:CGSizeMake(MAXFLOAT, MAXFLOAT)];
    ACCMasMaker(self.nextButton, {
        make.top.equalTo(self.mas_top).offset(8);
        make.right.equalTo(self).offset(-16);
        make.width.equalTo(@(sizeFits.width + 24));
        make.height.equalTo(@(36.0f));
    });
    
    _selectPhotoView = [[UIView alloc] init];
    [self addSubview:self.selectPhotoView];
    ACCMasMaker(self.selectPhotoView, {
        make.width.equalTo(@(80));
        make.height.equalTo(@(40));
        make.left.equalTo(self.mas_left).offset(16);
        make.centerY.equalTo(self.nextButton.mas_centerY);
    });

    CGFloat checkImageHeight = 22;
    NSString *resourceStr = @"";
    if (self.enableRepeatSelect) {
        resourceStr = @"icon_album_pressed_repeat_select";
    } else {
        resourceStr = @"icon_album_unselect";
    }

    _unCheckImageView = [[UIImageView alloc] initWithImage:CAKResourceImage(resourceStr)];
    [self.selectPhotoView addSubview:self.unCheckImageView];
    ACCMasMaker(_unCheckImageView, {
        make.left.equalTo(_selectPhotoView.mas_left);
        make.centerY.equalTo(self.nextButton.mas_centerY);
        make.width.height.equalTo(@(checkImageHeight));
    });
    
    if (self.selectedIconStyle == CAKAlbumAssetsSelectedIconStyleCheckMark) {
        _numberBackGroundImageView = [[UIImageView alloc] initWithImage:CAKResourceImage(@"icon_album_selected_checkmark")]; 
    } else {
        UIColor *cornerImageColor = CAKResourceColor(ACCColorPrimary);
        UIColor *numberLabelTextColor = CAKResourceColor(ACCColorConstTextInverse);
        CGFloat numberLabelFontSize = 12;
        UIImage *cornerImage = [UIImage cak_imageWithSize:CGSizeMake(checkImageHeight, checkImageHeight) cornerRadius:checkImageHeight * 0.5 backgroundColor:cornerImageColor];
        _numberBackGroundImageView = [[UIImageView alloc] initWithImage:cornerImage];
        _numberLabel = [[UILabel alloc] init];
//        _numberLabel.accrtl_viewType = ACCRTLViewTypeNormal;
        _numberLabel.font = [ACCFont() acc_systemFontOfSize:numberLabelFontSize];
        _numberLabel.textColor = numberLabelTextColor;
        _numberLabel.textAlignment = NSTextAlignmentCenter;
        [_numberBackGroundImageView addSubview:_numberLabel];
        ACCMasMaker(_numberLabel, {
            make.edges.equalTo(_numberBackGroundImageView);
        });
    }
    
    [_selectPhotoView addSubview:_numberBackGroundImageView];
    ACCMasMaker(_numberBackGroundImageView, {
        make.left.right.top.bottom.equalTo(self.unCheckImageView);
    });

    self.selectHintLabel = [[UILabel alloc] init];
    self.selectHintLabel.font = [ACCFont() acc_systemFontOfSize:15];
    self.selectHintLabel.textColor = CAKResourceColor(ACCUIColorIconPrimary);
    [self.selectPhotoView addSubview:self.selectHintLabel];
    
    ACCMasMaker(self.selectHintLabel, {
        make.top.equalTo(self.unCheckImageView.mas_top);
        make.bottom.equalTo(self.unCheckImageView.mas_bottom);
        make.left.equalTo(self.unCheckImageView.mas_right).offset(12);
        make.width.lessThanOrEqualTo(@(200));
    });
}

@end
