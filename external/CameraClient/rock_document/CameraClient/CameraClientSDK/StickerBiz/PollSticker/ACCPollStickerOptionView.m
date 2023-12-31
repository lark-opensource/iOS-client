//
//  ACCPollStickerOptionView.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/3/16.
//

#import "ACCPollStickerOptionView.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIFont+ACCAdditions.h>
#import <CreationKitArch/AWEInteractionStickerModel.h>

static CGFloat const ACCPollStickerOptionViewTextHeight = 18.f;
static CGFloat const ACCPollStickerOptionViewTextHPadding = 16.f;

@interface ACCPollStickerOptionView ()

@property (nonatomic, strong) UIView *percentView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *percentLabel;

@property (nonatomic, strong, readwrite) AWEInteractionVoteStickerOptionsModel *option;
@property (nonatomic, strong, readwrite) AWEInteractionVoteStickerInfoModel *voteInfo;
@property (nonatomic, assign) BOOL isAnimating;

@end

@implementation ACCPollStickerOptionView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    self.backgroundColor = [UIColor whiteColor];
    self.layer.masksToBounds = YES;
    self.layer.allowsEdgeAntialiasing = YES;
    self.clipsToBounds = YES;
    
    self.percentView = [[UIView alloc] init];
    self.percentView.alpha = 0.f;
    [self addSubview:self.percentView];
    ACCMasMaker(self.percentView, {
        make.left.equalTo(self);
        make.top.bottom.equalTo(self);
        make.width.mas_greaterThanOrEqualTo(0.f);
    });
    
    UILabel *percentLabel = [[UILabel alloc] init];
    percentLabel.alpha = 0.f;
    percentLabel.font = [UIFont acc_systemFontOfSize:15 weight:ACCFontWeightMedium];
    [percentLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    self.percentLabel = percentLabel;
    [self addSubview:percentLabel];
    ACCMasMaker(percentLabel, {
        make.centerY.equalTo(self);
        make.right.equalTo(@(-ACCPollStickerOptionViewTextHPadding));
        make.height.equalTo(@(ACCPollStickerOptionViewTextHeight));
        make.width.mas_greaterThanOrEqualTo(@0.f);
    });

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.font = [UIFont acc_systemFontOfSize:15 weight:ACCFontWeightMedium];
    titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.titleLabel = titleLabel;
    [self addSubview:titleLabel];
    ACCMasMaker(titleLabel, {
        make.centerY.equalTo(self);
        make.left.equalTo(@(ACCPollStickerOptionViewTextHPadding));
        make.height.equalTo(@(ACCPollStickerOptionViewTextHeight));
        make.right.equalTo(percentLabel.mas_left).offset(-5.f);
    });
}

- (void)updateUIConfig
{
    AWEInteractionVoteStickerInfoModel *voteInfo = self.voteInfo;
    AWEInteractionVoteStickerOptionsModel *option = self.option;
    switch (voteInfo.style) {
        case ACCPollStickerViewStyleResult:
        case ACCPollStickerViewStylePolled:
        {
            // 色卡中暂无，写这样抄过来
            if (voteInfo.selectOptionID == option.optionID && voteInfo.style != ACCPollStickerViewStyleResult) {
                self.percentView.backgroundColor = [UIColor colorWithRed:32/255.f green:213/255.f blue:236/255.f alpha:1];
            } else {
                self.percentView.backgroundColor = [UIColor colorWithRed:22/255.f green:24/255.f blue:35/255.f alpha:0.06];
            }
            self.titleLabel.textAlignment = NSTextAlignmentLeft;
            self.percentLabel.alpha = 1.f;
            self.percentView.alpha = 1.f;
        }
            break;
        default:
        {
            self.titleLabel.textAlignment = NSTextAlignmentCenter;
            self.percentLabel.alpha = 0.f;
            self.percentView.alpha = 0.f;
        }
            break;
    }
    
    
    self.titleLabel.textColor = ACCResourceColor(ACCUIColorConstSDPrimary);
    self.percentLabel.textColor = [UIColor colorWithRed:22/255.f green:24/255.f blue:35/255.f alpha:0.34];
}

- (void)configWithOption:(AWEInteractionVoteStickerOptionsModel *)option voteInfo:(AWEInteractionVoteStickerInfoModel *)voteInfo
{
    self.option = option;
    self.voteInfo = voteInfo;
    
    [self updateUIConfig];
    
    self.percentLabel.text = (voteInfo.style == ACCPollStickerViewStyleUnPolled ? @"" : [NSString stringWithFormat:@"%ld%%", (long)[self currentPercent]]);
    [self.percentLabel sizeToFit];
    self.titleLabel.text = option.optionText;
}

- (void)performSelectionAnimationWithOption:(AWEInteractionVoteStickerOptionsModel *)option voteInfo:(AWEInteractionVoteStickerInfoModel *)voteInfo completion:(void (^)(void))completion
{
    self.isAnimating = YES;
    [self configWithOption:option voteInfo:voteInfo];
    
    self.percentLabel.alpha = 0.f;
    self.percentView.alpha = 1.f;
    self.percentView.acc_width = 0.f;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.percentLabel.alpha = 1;
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        !completion ?: completion();
        self.isAnimating = NO;
    }];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.percentView.acc_width = ([self currentPercent] * 1.0 / 100.f) * self.bounds.size.width;
}

- (NSInteger)currentPercent
{
    NSInteger totalCount = 0;
    for (AWEInteractionVoteStickerOptionsModel *option in self.voteInfo.options) {
        totalCount += option.voteCount;
    }
    if (!totalCount) return 0;
    NSInteger p = lround(self.option.voteCount * 100.f / totalCount);
    return p;
}

@end
