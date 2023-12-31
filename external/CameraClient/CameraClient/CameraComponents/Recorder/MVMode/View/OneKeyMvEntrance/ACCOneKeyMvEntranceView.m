//
//  ACCOneKeyMvEntranceView.m
//  CameraClient-Pods-AwemeCore
//
//  Created by bytedance on 2021/10/11.
//

#import "ACCOneKeyMvEntranceView.h"
#import <Masonry/View+MASAdditions.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCColorNameDefines.h>

@interface ACCOneKeyMvEntranceView ()

@property (nonatomic, strong) UIImageView *oneKeyMvIcon;
@property (nonatomic, strong) UILabel *oneKeyMvTitle;
@property (nonatomic, strong) UILabel *oneKeyMvContent;
@property (nonatomic, strong) UIImageView *oneKeyMvArrow;

@end

@implementation ACCOneKeyMvEntranceView

- (instancetype)init
{
    self = [super init];
    if (self) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickSelfView)];
        self.userInteractionEnabled = YES;
        [self addGestureRecognizer:tap];
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    self.backgroundColor = ACCResourceColor(ACCColorConstBGContainer);
    
    self.layer.cornerRadius = 4;
    self.layer.masksToBounds = YES;
    self.frame = CGRectMake(0, 0, ACC_SCREEN_WIDTH - 16, 80);
    
    [self addSubview:self.oneKeyMvIcon];
    [self addSubview:self.oneKeyMvTitle];
    [self addSubview:self.oneKeyMvContent];
    [self addSubview:self.oneKeyMvArrow];
    
    ACCMasMaker(self.oneKeyMvIcon, {
        make.centerY.equalTo(self);
        make.left.equalTo(self.mas_left).offset(20);
        make.size.equalTo(@(CGSizeMake(40, 40)));
    });
    
    ACCMasMaker(self.oneKeyMvTitle, {
        make.left.equalTo(self.oneKeyMvIcon.mas_right).offset(22);
        make.top.equalTo(self.mas_top).offset(18);
    });
    
    ACCMasMaker(self.oneKeyMvArrow, {
        make.centerY.equalTo(self);
        make.right.equalTo(self.mas_right).offset(-24);
        make.size.equalTo(@(CGSizeMake(6, 12)));
    });
    
    ACCMasMaker(self.oneKeyMvContent, {
        make.left.equalTo(self.oneKeyMvTitle.mas_left);
        make.top.equalTo(self.oneKeyMvTitle.mas_bottom).offset(5);
        make.bottom.equalTo(self.mas_bottom).offset(-18);
        make.right.equalTo(self.oneKeyMvArrow.mas_left).offset(-20);
    });
}

# pragma mark - getter

- (UIImageView *)oneKeyMvIcon
{
    if (!_oneKeyMvIcon) {
        _oneKeyMvIcon = [[UIImageView alloc] initWithImage:ACCResourceImage(@"icon_one_key_mv")];
    }
    return _oneKeyMvIcon;
}

- (UILabel *)oneKeyMvTitle
{
    if (!_oneKeyMvTitle) {
        _oneKeyMvTitle = [[UILabel alloc] init];
        _oneKeyMvTitle.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightBold];
        _oneKeyMvTitle.textColor = [UIColor whiteColor];
        _oneKeyMvTitle.numberOfLines = 1;
        _oneKeyMvTitle.text = @"一键成片";
    }
    return _oneKeyMvTitle;
}

- (UILabel *)oneKeyMvContent
{
    if (!_oneKeyMvContent) {
        _oneKeyMvContent = [[UILabel alloc] init];
        _oneKeyMvContent.font = [ACCFont() systemFontOfSize:13 weight:ACCFontWeightRegular];
        _oneKeyMvContent.textColor = ACCResourceColor(ACCColorConstTextInverse4);
        _oneKeyMvContent.text = @"模版选择困难？试试素材匹配模板！";
        _oneKeyMvContent.adjustsFontSizeToFitWidth = true;
        _oneKeyMvContent.numberOfLines = 1;
    }
    return _oneKeyMvContent;
}

- (UIImageView *)oneKeyMvArrow
{
    if (!_oneKeyMvArrow) {
        _oneKeyMvArrow = [[UIImageView alloc] initWithImage:ACCResourceImage(@"icon_one_key_mv_right_arrow")];
    }
    return _oneKeyMvArrow;
}

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return [NSString stringWithFormat:@"%@，%@", self.oneKeyMvTitle.text, self.oneKeyMvContent.text];
}

# pragma mark - action

- (void)clickSelfView
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(jumpToAlbumPage:)]) {
        [self.delegate jumpToAlbumPage:@"banner"];
    }
}


@end
