//
//  ACCMusicPanelToolbar.m
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/6/28.
//

#import "ACCMusicPanelToolbar.h"
#import <CreativeKit/UIImage+ACCAdditions.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCFontProtocol.h>


@interface ACCMusicPanelBottomToolbar ()

@property (nonatomic, weak) id<ACCMusicPanelBottomToolbarDelegate> delegate;

@property (nonatomic, strong) UIImageView *musicScoreCheckImageView;
@property (nonatomic, strong) UILabel *musicScoreCheckLabel;
@property (nonatomic, strong) UIButton *musicScoreButton;

@property (nonatomic, strong) UIImageView *originMusicCheckImageView;
@property (nonatomic, strong) UILabel *originMusicCheckLabel;
@property (nonatomic, strong) UIButton *originMusicButton;

@property (nonatomic, strong) UIImageView *volumeImageView;
@property (nonatomic, strong) UILabel *volumeLabel;
@property (nonatomic, strong) UIButton *volumeButton;

@property (nonatomic, strong) UIColor *unselectedColor;
@property (nonatomic, strong) UIColor *labelColor;

@property (nonatomic, assign) BOOL isDarkBackground;

@end

@implementation ACCMusicPanelBottomToolbar

- (instancetype)initWithFrame:(CGRect)frame isDarkBackground:(BOOL)isDarkBackground delegate:(id<ACCMusicPanelBottomToolbarDelegate>)delegate {
    self = [super initWithFrame:frame];
    if (self) {
        self.isDarkBackground = isDarkBackground;
        self.delegate = delegate;
        [self setupUI];
    }
    return  self;
}

- (void)setupUI {
    UIImage *uncheckedImage = ACCResourceImage(@"icon_filter_box_uncheck");
    UIImage *volumeImage = ACCResourceImage(@"icon_volume");
    
    if (self.isDarkBackground) {
        self.unselectedColor = ACCResourceColor(ACCColorConstTextInverse4);
        self.labelColor = ACCResourceColor(ACCUIColorConstTextInverse);
        uncheckedImage = [uncheckedImage acc_ImageWithTintColor:self.unselectedColor];
    } else {
        self.unselectedColor = ACCResourceColor(ACCUIColorConstIconTertiary);
        self.labelColor = ACCResourceColor(ACCColorTextReverse);
        uncheckedImage = [uncheckedImage acc_ImageWithTintColor:self.unselectedColor];
        volumeImage = [volumeImage acc_ImageWithTintColor:self.labelColor];
    }
    
    // default config
    self.musicScoreCheckImageView = ({
        UIImageView *musicScoreCheckImageView = [[UIImageView alloc] init];
        [musicScoreCheckImageView setImage:uncheckedImage];
        musicScoreCheckImageView.isAccessibilityElement = NO;
        [self addSubview:musicScoreCheckImageView];
        ACCMasMaker(musicScoreCheckImageView, {
            make.left.equalTo(@16);
            make.height.width.equalTo(@20);
            make.centerY.equalTo(self);
        })
        musicScoreCheckImageView;
    });
   
    self.musicScoreCheckLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.text = ACCLocalizedCurrentString(@"av_music");
        label.textColor = self.labelColor;
        label.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightRegular];
        label.textAlignment = NSTextAlignmentLeft;
        label.adjustsFontSizeToFitWidth = YES;
        label.isAccessibilityElement = NO;
        [self addSubview:label];
        ACCMasMaker(label, {
            make.left.equalTo(self.musicScoreCheckImageView.mas_right).offset(8);
            make.width.equalTo(@46);
            make.centerY.equalTo(self);
        });
        label;
    });
 
    self.musicScoreButton = ({
        UIButton *button = [[UIButton alloc] init];
        [button addTarget:self action:@selector(musicScoreButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        ACCMasMaker(button, {
            make.left.top.bottom.equalTo(self);
            make.width.equalTo(@90);
        });
        button;
    });
    self.musicScoreButton.isAccessibilityElement = YES;
    self.musicScoreButton.accessibilityLabel = self.musicScoreCheckLabel.text;
    self.musicScoreButton.accessibilityTraits = UIAccessibilityTraitButton;
    self.musicScoreButton.accessibilityHint = self.musicScoreSelected ? @"已选中" : @"未选中";
    
    self.originMusicCheckImageView = ({
        UIImageView *originMusicCheckImageView = [[UIImageView alloc] init];
        [originMusicCheckImageView setImage:uncheckedImage];
        originMusicCheckImageView.isAccessibilityElement = NO;
        [self addSubview:originMusicCheckImageView];
        ACCMasMaker(originMusicCheckImageView, {
            make.left.equalTo(@106);
            make.height.width.equalTo(@20);
            make.centerY.equalTo(self);
        })
        originMusicCheckImageView;
    });
    
    self.originMusicCheckLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.text = @"视频原声";
        label.textColor = self.labelColor;
        label.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightRegular];
        label.textAlignment = NSTextAlignmentLeft;
        label.adjustsFontSizeToFitWidth = YES;
        label.isAccessibilityElement = NO;
        [self addSubview:label];
        ACCMasMaker(label, {
            make.left.equalTo(self.originMusicCheckImageView.mas_right).offset(8);
            make.width.equalTo(@76);
            make.centerY.equalTo(self);
        });
        label;
    });
    
    self.originMusicButton = ({
        UIButton *button = [[UIButton alloc] init];
        [button addTarget:self action:@selector(originMusicButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        ACCMasMaker(button, {
            make.left.equalTo(@90);
            make.top.bottom.equalTo(self);
            make.width.equalTo(@120);
        });
        button;
    });
    self.originMusicButton.isAccessibilityElement = YES;
    self.originMusicButton.accessibilityLabel = self.originMusicCheckLabel.text;
    self.originMusicButton.accessibilityTraits = UIAccessibilityTraitButton;
    self.originMusicButton.accessibilityHint = self.originMusicSelected ? @"已选中" : @"未选中";
    
    self.volumeLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.text = ACCLocalizedCurrentString(@"volume");
        label.textColor = self.labelColor;
        label.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightRegular];
        label.textAlignment = NSTextAlignmentLeft;
        label.adjustsFontSizeToFitWidth = YES;
        label.isAccessibilityElement = NO;
        [self addSubview:label];
        ACCMasMaker(label, {
            make.right.equalTo(self);
            make.width.equalTo(@46);
            make.centerY.equalTo(self);
        });
        label;
    });
    
    self.volumeImageView = ({
        UIImageView *volumeImageView = [[UIImageView alloc] init];
        [volumeImageView setImage:volumeImage];
        volumeImageView.isAccessibilityElement = NO;
        [self addSubview:volumeImageView];
        ACCMasMaker(volumeImageView, {
            make.right.equalTo(self.volumeLabel.mas_left).offset(-8);
            make.height.width.equalTo(@20);
            make.centerY.equalTo(self);
        })
        volumeImageView;
    });
    
    self.volumeButton = ({
        UIButton *button = [[UIButton alloc] init];
        [button addTarget:self action:@selector(volumeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        ACCMasMaker(button, {
            make.right.top.bottom.equalTo(self);
            make.width.equalTo(@90);
        });
        button;
    });
    self.volumeButton.isAccessibilityElement = YES;
    self.volumeButton.accessibilityLabel = self.volumeLabel.text;
    self.volumeButton.accessibilityTraits = UIAccessibilityTraitButton;
}

#pragma mark - getter & setter

- (void)setMusicScoreSelected:(BOOL)musicScoreSelected {
    _musicScoreSelected = musicScoreSelected;
    self.musicScoreCheckLabel.textColor = self.labelColor;
    if (musicScoreSelected) {
        [self.musicScoreCheckImageView  setImage:ACCResourceImage(@"icon_filter_box_check")];
    } else {
        UIImage *uncheckedImage = ACCResourceImage(@"icon_filter_box_uncheck");
        uncheckedImage = [uncheckedImage acc_ImageWithTintColor:self.unselectedColor];
        [self.musicScoreCheckImageView setImage:uncheckedImage];
    }
    self.musicScoreButton.accessibilityHint = musicScoreSelected ? @"已选中" : @"未选中";
}

- (void)setMusicScoreDisable:(BOOL)musicScoreDisable {
    _musicScoreDisable = musicScoreDisable;
    self.musicScoreCheckLabel.alpha = musicScoreDisable ? 0.5 : 1.0;
    if (self.musicScoreSelected) {
        self.musicScoreCheckImageView.alpha = musicScoreDisable ? 0.5 : 1.0;
    } else {
        self.musicScoreCheckImageView.alpha = 1.0;
    }
}

- (void)setMusicScoreHide:(BOOL)musicScoreHide
{
    _musicScoreHide = musicScoreHide;
    self.musicScoreCheckLabel.hidden = musicScoreHide;
    self.musicScoreCheckImageView.hidden = musicScoreHide;
    self.musicScoreButton.hidden = musicScoreHide;
}

- (void)setOriginMusicSelected:(BOOL)originMusicSelected {
    _originMusicSelected = originMusicSelected;
    self.originMusicCheckLabel.textColor = self.labelColor;
    if (originMusicSelected) {
        [self.originMusicCheckImageView setImage:ACCResourceImage(@"icon_filter_box_check")];
    } else {
        UIImage *uncheckedImage = ACCResourceImage(@"icon_filter_box_uncheck");
        if (self.isDarkBackground) {
            uncheckedImage = [uncheckedImage acc_ImageWithTintColor:self.unselectedColor];
        } else {
            uncheckedImage = [uncheckedImage acc_ImageWithTintColor:self.unselectedColor];
        }
        [self.originMusicCheckImageView setImage:uncheckedImage];
    }
    self.originMusicButton.accessibilityHint = originMusicSelected ? @"已选中" : @"未选中";
}

- (void)setOriginMusicDisable:(BOOL)originMusicDisable {
    _originMusicDisable = originMusicDisable;
    self.originMusicCheckLabel.alpha = originMusicDisable ? 0.5 : 1.0;
    if (self.originMusicSelected) {
        self.originMusicCheckImageView.alpha = originMusicDisable ? 0.5 : 1.0;
    } else {
        self.originMusicCheckImageView.alpha = 1.0;
    }
}

- (void)setOriginMusicScoreHide:(BOOL)originMusicScoreHide {
    _originMusicScoreHide = originMusicScoreHide;
    self.originMusicCheckLabel.hidden = originMusicScoreHide;
    self.originMusicCheckImageView.hidden = originMusicScoreHide;
    self.originMusicButton.hidden = originMusicScoreHide;
}

- (void)setVolumeDisable:(BOOL)volumeDisable {
    _volumeDisable = volumeDisable;
    self.volumeLabel.alpha = volumeDisable ? 0.5 : 1.0;
    self.volumeImageView.alpha = volumeDisable ? 0.5 : 1.0;
}

- (void)setVolumeHide:(BOOL)volumeHide {
    _volumeHide = volumeHide;
    self.volumeLabel.hidden = volumeHide;
    self.volumeImageView.hidden = volumeHide;
    self.volumeButton.hidden = volumeHide;
}

#pragma mark - public

- (void)hiddenOriginMusicView {
    self.volumeDisable = YES;
    self.volumeLabel.hidden = YES;
    self.volumeImageView.hidden = YES;
    self.volumeButton.hidden = YES;
    
    self.originMusicDisable = YES;
    self.originMusicCheckImageView.hidden = YES;
    self.originMusicCheckLabel.hidden = YES;
    self.originMusicButton.hidden = YES;
}

#pragma mark - action

- (void)musicScoreButtonTapped:(UIButton *)sender {
    if (self.musicScoreDisable) {
        return;
    }
     BOOL selected = !self.musicScoreSelected;
    if ([self.delegate respondsToSelector:@selector(toolbarMusicScoreSelected:)]) {
        if ([self.delegate toolbarMusicScoreSelected:selected]) {
            self.musicScoreSelected = selected;
        }
    }
}

- (void)originMusicButtonTapped:(UIButton *)sender {
    if (self.originMusicDisable) {
        return;
    }
    self.originMusicSelected = !self.originMusicSelected;
    if ([self.delegate respondsToSelector:@selector(toolbarOriginMusicSelected:)]) {
        [self.delegate toolbarOriginMusicSelected:self.originMusicSelected];
    }
}

- (void)volumeButtonTapped:(UIButton *)sender {
    if (self.volumeDisable) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(toolbarVolumeTapped)]) {
        [self.delegate toolbarVolumeTapped];
    }
}

@end
