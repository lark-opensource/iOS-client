//
//  TMAVideoLockButton.m
//  OPPluginBiz
//
//  Created by zhujingcheng on 2/8/23.
//

#import "TMAVideoLockButton.h"
#import <OPFoundation/UIImage+EMA.h>
#import <OPFoundation/BDPI18N.h>
#import <Masonry/Masonry.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <ByteDanceKit/UIView+BTDAdditions.h>
#import <ByteDanceKit/UIColor+BTDAdditions.h>

@interface TMAVideoLockButton ()

@property (nonatomic, strong) UILabel *lockedLabel;
@property (nonatomic, strong) UIImageView *iconView;

@end

@implementation TMAVideoLockButton

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    self.backgroundColor = [UIColor btd_colorWithHexString:@"#1F232999"];
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = 20;
    [self addTarget:self action:@selector(onButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:self.iconView];
    [self.iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self).mas_offset(10);
        make.centerY.mas_equalTo(self);
        make.width.height.mas_equalTo(20);
        make.trailing.mas_equalTo(self).mas_offset(-10);
    }];
}

- (void)onButtonTapped {
    self.locked = !self.locked;
}

- (void)setLocked:(BOOL)locked {
    if (_locked == locked) {
        return;
    }
    _locked = locked;
    [self updateViews];
    !self.tapAction ?: self.tapAction(_locked);
}

- (void)updateViews {
    if (self.locked) {
        [self.iconView setImage:[UIImage ema_imageNamed:@"op_video_lock_btn"]];
        [self.iconView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.mas_equalTo(self).mas_offset(10);
            make.centerY.mas_equalTo(self);
            make.width.height.mas_equalTo(20);
        }];
        
        [self addSubview:self.lockedLabel];
        [self.lockedLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.mas_equalTo(self.iconView.mas_trailing).mas_offset(8);
            make.centerY.mas_equalTo(self);
            make.width.mas_equalTo(self.lockedTextWidth);
            make.trailing.mas_equalTo(self).mas_offset(-10);
        }];
    } else {
        [self.iconView setImage:[UIImage ema_imageNamed:@"op_video_unlock_btn"]];
        [self hideTextTip];
    }
}

#pragma mark - Public

- (void)hideTextTip {
    [self.iconView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self).mas_offset(10);
        make.centerY.mas_equalTo(self);
        make.width.height.mas_equalTo(20);
        make.trailing.mas_equalTo(self).mas_offset(-10);
    }];
    [self.lockedLabel removeFromSuperview];
}

#pragma mark - Getter

- (UILabel *)lockedLabel {
    if (!_lockedLabel) {
        _lockedLabel = [[UILabel alloc] init];
        _lockedLabel.font = [UIFont systemFontOfSize:14];
        _lockedLabel.textColor = [UIColor btd_colorWithHexString:@"#EDF0F1"];
        _lockedLabel.text = BDPI18n.LittleApp_VideoCompt_Locked;
    }
    return _lockedLabel;
}

- (UIImageView *)iconView {
    if (!_iconView) {
        _iconView = [[UIImageView alloc] initWithImage:[UIImage ema_imageNamed:@"op_video_unlock_btn"]];
    }
    return _iconView;
}

- (CGFloat)lockedTextWidth {
    return [self.lockedLabel.text btd_widthWithFont:self.lockedLabel.font height:self.btd_height];
}

@end
