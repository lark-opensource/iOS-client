//
//  ACCModernLiveStickerView.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/8/14.
//

#import "ACCModernLiveStickerView.h"
#import "AWEInteractionLiveStickerModel.h"
#import "ACCConfigKeyDefines.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/UIFont+ACCAdditions.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <lottie-ios/Lottie/Lottie.h>
#import <CreativeKit/NSString+CameraClientResource.h>
#import <CreativeKit/NSString+CameraClientResource.h>

static CGFloat const kACCModernLiveStickerViewHorizonalPadding = 10.f;

@interface ACCModernLiveStickerView()

@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) LOTAnimationView *animatedView;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIButton *toSeeBtn;

@property (nonatomic, assign) BOOL useColorfulStyle;

@end

@implementation ACCModernLiveStickerView

+ (ACCLiveStickerView *)createLiveStickerViewWithModel:(AWEInteractionStickerModel *)model
{
    ACCLiveStickerView *stickerView = nil;
    if ([model isKindOfClass:AWEInteractionLiveStickerModel.class]) {
        ((AWEInteractionLiveStickerModel *)model).style = ACCConfigInt(kConfigInt_anchor_video_preview);
        if (((AWEInteractionLiveStickerModel *)model).style == ACCLiveStickerViewStyleDefault) {
            stickerView = [[ACCLiveStickerView alloc] initWithStickerModel:model];
        } else {
            stickerView = [[ACCModernLiveStickerView alloc] initWithStickerModel:model];
        }
        [stickerView configWithInfo:((AWEInteractionLiveStickerModel *)model).liveInfo];
    }
    return stickerView;
}

- (void)setupUI
{
    BOOL useColorfulStyle = ((AWEInteractionLiveStickerModel *)self.stickerModel).style == ACCLiveStickerViewStyleModernColorful;
    self.useColorfulStyle = useColorfulStyle;
    
    UIImageView *bgImageView = [[UIImageView alloc] init];
    bgImageView.image = useColorfulStyle ? ACCResourceImage(@"sticker_live_color_bg") : ACCResourceImage(@"live_sticker_big_bg");
    bgImageView.contentMode = UIViewContentModeScaleAspectFit;
    bgImageView.layer.allowsEdgeAntialiasing = YES;
    self.bgImageView = bgImageView;
    [self addSubview:bgImageView];
    ACCMasMaker(bgImageView, {
        make.edges.equalTo(self);
    });
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"直播预告";
    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.textColor = useColorfulStyle ? ACCResourceColor(ACCColorTextReverse) : ACCResourceColor(ACCUIColorConstTextSecondary);
    titleLabel.font = [UIFont acc_systemFontOfSize:13.f weight:ACCFontWeightSemibold];
    [self addSubview:titleLabel];
    ACCMasMaker(titleLabel, {
        make.left.equalTo(@(kACCModernLiveStickerViewHorizonalPadding));
        make.right.equalTo(@(-kACCModernLiveStickerViewHorizonalPadding));
        make.top.equalTo(@17.f);
        make.height.equalTo(@17.f);
    });
    self.titleLabel = titleLabel;
    
    LOTAnimationView *animatedView = [LOTAnimationView animationWithFilePath:ACCResourceFile(@"douyin_live_icon_lottie_50.json")];
    LOTKeypath *keypath = [LOTKeypath keypathWithString:@"**.Color"];
    LOTColorValueCallback *colorCallback = [LOTColorValueCallback withCGColor:(useColorfulStyle ? ACCResourceColor(ACCColorLiveColorEnd) : ACCResourceColor(ACCColorTextReverse2)).CGColor];
    [animatedView setValueDelegate:colorCallback forKeypath:keypath];
    animatedView.contentMode = UIViewContentModeScaleAspectFit;
    animatedView.loopAnimation = YES;
    [self addSubview:animatedView];
    ACCMasMaker(animatedView, {
        make.left.equalTo(@(kACCModernLiveStickerViewHorizonalPadding));
        make.centerY.equalTo(titleLabel.mas_centerY);
        make.width.equalTo(@11.f);
        make.height.equalTo(@11.f);
    });
    self.animatedView = animatedView;
    [self.animatedView stop];
    self.animatedView.hidden = YES;
    
    UILabel *dateLabel = [[UILabel alloc] init];
    dateLabel.textAlignment = NSTextAlignmentLeft;
    dateLabel.textColor = useColorfulStyle ? ACCResourceColor(ACCUIColorConstTextSecondary) : ACCResourceColor(ACCUIColorConstTextTertiary);
    dateLabel.font = [UIFont acc_systemFontOfSize:10.f weight:useColorfulStyle ? ACCFontWeightRegular : ACCFontWeightMedium];
    [self addSubview:dateLabel];
    ACCMasMaker(dateLabel, {
        make.left.equalTo(@(kACCModernLiveStickerViewHorizonalPadding));
        make.right.equalTo(@(-kACCModernLiveStickerViewHorizonalPadding));
        make.top.equalTo(titleLabel.mas_bottom).equalTo(@8.f);
        make.height.equalTo(@14.f);
    });
    self.dateLabel = dateLabel;
    
    UILabel *timeLabel = [[UILabel alloc] init];
    timeLabel.textAlignment = NSTextAlignmentLeft;
    timeLabel.textColor = useColorfulStyle ? ACCResourceColor(ACCColorTextReverse) : ACCResourceColor(ACCUIColorConstTextSecondary);
    timeLabel.font = [UIFont acc_systemFontOfSize:13.f weight:ACCFontWeightSemibold];
    [self addSubview:timeLabel];
    ACCMasMaker(timeLabel, {
        make.left.equalTo(@(kACCModernLiveStickerViewHorizonalPadding));
        make.right.equalTo(@(-kACCModernLiveStickerViewHorizonalPadding));
        make.top.equalTo(dateLabel.mas_bottom).equalTo(@1.5);
        make.height.equalTo(@18.f);
    });
    self.timeLabel = timeLabel;
    
    UIButton *toSeeBtn = [[UIButton alloc] init];
    toSeeBtn.backgroundColor = useColorfulStyle ? ACCResourceColor(ACCColorLiveColorEnd) : ACCResourceColor(ACCColorConstTextInverse3);
    toSeeBtn.layer.cornerRadius = 9.f;
    toSeeBtn.layer.masksToBounds = YES;
    toSeeBtn.titleLabel.font = [UIFont acc_systemFontOfSize:11.f weight:ACCFontWeightMedium];
    toSeeBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    toSeeBtn.contentEdgeInsets = UIEdgeInsetsMake(2.f, 2.f, 2.f, 2.f);
    toSeeBtn.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-5.f, -5.f, -5.f, -5.f);
    [toSeeBtn setTitle:@"想看" forState:UIControlStateNormal];
    [toSeeBtn setTitleColor:useColorfulStyle ? [UIColor whiteColor] : ACCResourceColor(ACCUIColorConstTextPrimary) forState:UIControlStateNormal];
    [toSeeBtn addTarget:self action:@selector(clickToSeeBtn) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:toSeeBtn];
    ACCMasMaker(toSeeBtn, {
        make.right.equalTo(@(-6.f));
        make.width.equalTo(@40.f);
        make.centerY.equalTo(timeLabel);
        make.height.equalTo(@18.f);
    });
    self.toSeeBtn = toSeeBtn;
    self.toSeeBtn.hidden = YES;
}

- (void)updateUI:(AWEInteractionLiveStickerInfoModel *)liveInfo
{
    BOOL useColorfulStyle = self.useColorfulStyle;
    BOOL timeValid = [liveInfo liveTimeValid];
    BOOL isLiving = liveInfo.status == ACCLiveStickerViewStatusLiving;
    
    ACCMasUpdate(self.titleLabel, {
        make.left.equalTo(@(liveInfo.status == ACCLiveStickerViewStatusLiving ? kACCModernLiveStickerViewHorizonalPadding+17.f : kACCModernLiveStickerViewHorizonalPadding));
    });
    
    self.titleLabel.text = isLiving ? @"正在直播" : @"直播预告";
    
    self.dateLabel.font = [UIFont acc_systemFontOfSize:timeValid ? 10.f : 11.f weight:useColorfulStyle ? ACCFontWeightRegular : ACCFontWeightMedium];
    self.timeLabel.textColor = timeValid ? ACCResourceColor(ACCUIColorConstTextSecondary) : ACCResourceColor(ACCUIColorConstTextTertiary);
    
    self.animatedView.hidden = !isLiving;
    if (isLiving) {
        [self.animatedView play];
    } else {
        [self.animatedView stop];
    }
    
    if (liveInfo.btnClicked) {
        [self.toSeeBtn setImage:useColorfulStyle ? ACCResourceImage(@"icon_edit_bar_done_light") : ACCResourceImage(@"icon_edit_bar_done_dark") forState:UIControlStateNormal];
        [self.toSeeBtn setTitle:@"" forState:UIControlStateNormal];
    } else {
        [self.toSeeBtn setImage:nil forState:UIControlStateNormal];
        [self.toSeeBtn setTitle:@"想看" forState:UIControlStateNormal];
    }
    
    if (useColorfulStyle) {
        self.bgImageView.image = timeValid ? ACCResourceImage(@"sticker_live_color_bg") :  ACCResourceImage(@"sticker_live_gray_bg");
        self.titleLabel.textColor = isLiving ? ACCResourceColor(ACCColorLiveColorEnd) : ACCResourceColor(ACCColorTextReverse);
        self.dateLabel.textColor = timeValid ? ACCResourceColor(ACCUIColorConstTextSecondary) : ACCResourceColor(ACCColorTextReverse3);
        self.timeLabel.textColor = timeValid ? ACCResourceColor(ACCColorTextReverse) : ACCResourceColor(ACCColorTextReverse4);
    }
    
    self.toSeeBtn.hidden = !liveInfo.showToSee;
}

- (void)clickToSeeBtn
{
    ACCBLOCK_INVOKE(self.clickOnToSeeBtn);
}

@end
