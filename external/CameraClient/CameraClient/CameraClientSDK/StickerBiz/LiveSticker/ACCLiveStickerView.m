//
//  ACCLiveStickerView.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/1/4.
//

#import "ACCLiveStickerView.h"
#import "AWEInteractionLiveStickerModel.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/UIFont+ACCAdditions.h>
#import <CreativeKit/UIColor+CameraClientResource.h>

static CGFloat const kACCLiveStickerViewHorizonalPadding = 10.f;

@interface ACCLiveStickerView()

@property (nonatomic, strong, readwrite) AWEInteractionLiveStickerInfoModel *liveInfo;

@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) CAShapeLayer *dashLineLayer;
@property (nonatomic, strong) UIImageView *tagView;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIButton *toSeeBtn;

@property (nonatomic, assign) BOOL responder;
@property (nonatomic, assign) ACCLiveStickerViewStyle style;
@end

@implementation ACCLiveStickerView
@synthesize coordinateDidChange;
@synthesize stickerContainer;
@synthesize transparent = _transparent;
@synthesize stickerModel;
@synthesize clickOnToSeeBtn;
@synthesize stickerId = _stickerId;
@synthesize triggerDragDeleteCallback = _triggerDragDeleteCallback;

- (id)copyForContext:(id)contextId
{
    AWEInteractionLiveStickerModel *stickerModel = [self.stickerModel copy];
    stickerModel.liveInfo = [self.liveInfo copy];
    ACCLiveStickerView *viewCopy = [[[self class] alloc] initWithStickerModel:stickerModel];
    viewCopy.frame = self.frame;
    [viewCopy configWithInfo:stickerModel.liveInfo];
    return viewCopy;
}

- (instancetype)initWithStickerModel:(AWEInteractionStickerModel *)model
{
    self = [super init];
    if (self) {
        if ([model isKindOfClass:AWEInteractionLiveStickerModel.class]) {
            self.stickerModel = model;
            self.style = ((AWEInteractionLiveStickerModel *)model).style;
            [self setupUI];
        }
    }
    return self;
}

- (void)setupUI
{
    UIImageView *bgImageView = [[UIImageView alloc] init];
    bgImageView.image = ACCResourceImage(@"live_sticker_bg");
    bgImageView.contentMode = UIViewContentModeScaleAspectFit;
    bgImageView.layer.allowsEdgeAntialiasing = YES;
    self.bgImageView = bgImageView;
    [self addSubview:bgImageView];
    ACCMasMaker(bgImageView, {
        make.edges.equalTo(self);
    });
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"直播预告";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = ACCResourceColor(ACCUIColorConstTextSecondary);
    titleLabel.font = [UIFont acc_systemFontOfSize:13.f weight:ACCFontWeightSemibold];
    [self addSubview:titleLabel];
    ACCMasMaker(titleLabel, {
        make.left.equalTo(@(kACCLiveStickerViewHorizonalPadding));
        make.right.equalTo(@(-kACCLiveStickerViewHorizonalPadding));
        make.top.equalTo(@14.f);
        make.height.equalTo(@16.f);
    });
    self.titleLabel = titleLabel;
    
    CAShapeLayer *dashLineLayer = [CAShapeLayer layer];
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, &CGAffineTransformIdentity, 0, 0);
    CGPathAddLineToPoint(path, &CGAffineTransformIdentity, 88.f, 0);
    dashLineLayer.path = path;
    dashLineLayer.lineWidth = 0.5;
    dashLineLayer.lineDashPattern = @[@3, @3];
    dashLineLayer.lineCap = kCALineCapButt;
    dashLineLayer.strokeColor = ACCResourceColor(ACCUIColorConstTextTertiary2).CGColor;
    dashLineLayer.frame = CGRectMake(0.f, 32.f, 88.f, 0.5);
    CGPathRelease(path);
    [self.layer addSublayer:dashLineLayer];
    self.dashLineLayer = dashLineLayer;
    
    UIImageView *tagView = [[UIImageView alloc] init];
    tagView.image = ACCResourceImage(@"ic_living_tag");
    tagView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:tagView];
    ACCMasMaker(tagView, {
        make.left.equalTo(@(kACCLiveStickerViewHorizonalPadding));
        make.centerY.equalTo(titleLabel.mas_centerY);
        make.width.equalTo(@10.f);
        make.height.equalTo(@10.f);
    });
    self.tagView = tagView;
    self.tagView.hidden = YES;
    
    UILabel *dateLabel = [[UILabel alloc] init];
    dateLabel.textAlignment = NSTextAlignmentCenter;
    dateLabel.textColor = ACCResourceColor(ACCUIColorConstTextTertiary);
    dateLabel.font = [UIFont acc_systemFontOfSize:10.f weight:ACCFontWeightMedium];
    [self addSubview:dateLabel];
    ACCMasMaker(dateLabel, {
        make.left.equalTo(@(kACCLiveStickerViewHorizonalPadding));
        make.right.equalTo(@(-kACCLiveStickerViewHorizonalPadding));
        make.top.equalTo(titleLabel.mas_bottom).equalTo(@8.f);
        make.height.equalTo(@13.f);
    });
    self.dateLabel = dateLabel;
    
    UILabel *timeLabel = [[UILabel alloc] init];
    timeLabel.textAlignment = NSTextAlignmentCenter;
    timeLabel.textColor = ACCResourceColor(ACCUIColorConstTextSecondary);
    timeLabel.font = [UIFont acc_systemFontOfSize:13.f weight:ACCFontWeightSemibold];
    [self addSubview:timeLabel];
    ACCMasMaker(timeLabel, {
        make.left.equalTo(@(kACCLiveStickerViewHorizonalPadding));
        make.right.equalTo(@(-kACCLiveStickerViewHorizonalPadding));
        make.top.equalTo(dateLabel.mas_bottom).equalTo(@1.5);
        make.height.equalTo(@18.f);
    });
    self.timeLabel = timeLabel;
    
    UIButton *toSeeBtn = [[UIButton alloc] init];
    toSeeBtn.backgroundColor = ACCResourceColor(ACCColorConstTextInverse3);
    toSeeBtn.layer.cornerRadius = 9.f;
    toSeeBtn.layer.masksToBounds = YES;
    toSeeBtn.titleLabel.font = [UIFont acc_systemFontOfSize:11.f weight:ACCFontWeightMedium];
    toSeeBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    toSeeBtn.contentEdgeInsets = UIEdgeInsetsMake(2.f, 2.f, 2.f, 2.f);
    toSeeBtn.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-5.f, -5.f, -5.f, -5.f);
    [toSeeBtn setTitle:@"想看" forState:UIControlStateNormal];
    [toSeeBtn setTitleColor:ACCResourceColor(ACCUIColorConstTextPrimary) forState:UIControlStateNormal];
    [toSeeBtn addTarget:self action:@selector(clickToSeeBtn) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:toSeeBtn];
    ACCMasMaker(toSeeBtn, {
        make.right.equalTo(@(-6.f));
        make.width.equalTo(@40.f);
        make.top.equalTo(dateLabel.mas_bottom).equalTo(@1.5);
        make.height.equalTo(@18.f);
    });
    self.toSeeBtn = toSeeBtn;
    self.toSeeBtn.hidden = YES;
}

- (void)updateUI:(AWEInteractionLiveStickerInfoModel *)liveInfo
{
    BOOL showToSee = liveInfo.showToSee;
    ACCMasUpdate(self.titleLabel, {
        make.top.equalTo(@(showToSee ? 18.f : 12.f));
        make.left.equalTo(@(liveInfo.status == ACCLiveStickerViewStatusLiving ? kACCLiveStickerViewHorizonalPadding+12.f : kACCLiveStickerViewHorizonalPadding));
    });
    
    ACCMasUpdate(self.dateLabel, {
        make.top.equalTo(self.titleLabel.mas_bottom).equalTo(@(showToSee ? 8.f : 10.f));
    });
    
    self.bgImageView.image = showToSee ? ACCResourceImage(@"live_sticker_big_bg") : ACCResourceImage(@"live_sticker_bg");
    self.titleLabel.textAlignment = showToSee ? NSTextAlignmentLeft : NSTextAlignmentCenter;
    self.titleLabel.text = liveInfo.status == ACCLiveStickerViewStatusLiving ? @"正在直播" : @"直播预告";
    self.tagView.hidden = (liveInfo.status != ACCLiveStickerViewStatusLiving);
    self.dashLineLayer.hidden = liveInfo.showToSee;
    self.dateLabel.textAlignment = showToSee ? NSTextAlignmentLeft : NSTextAlignmentCenter;
    self.dateLabel.font = [UIFont acc_systemFontOfSize:[liveInfo liveTimeValid] ? 10.f : 11.f weight:ACCFontWeightMedium];
    self.timeLabel.textAlignment = showToSee ? NSTextAlignmentLeft : NSTextAlignmentCenter;
    self.timeLabel.textColor = [liveInfo liveTimeValid] ? ACCResourceColor(ACCUIColorConstTextSecondary) : ACCResourceColor(ACCUIColorConstTextTertiary);
    self.timeLabel.font = [UIFont acc_systemFontOfSize:[liveInfo liveTimeValid] ? 13.f : 11.f weight:ACCFontWeightSemibold];
    if (liveInfo.btnClicked) {
        [self.toSeeBtn setImage:ACCResourceImage(@"icon_edit_bar_done_dark") forState:UIControlStateNormal];
        [self.toSeeBtn setTitle:@"" forState:UIControlStateNormal];
    } else {
        [self.toSeeBtn setImage:nil forState:UIControlStateNormal];
        [self.toSeeBtn setTitle:@"想看" forState:UIControlStateNormal];
    }
    
    self.toSeeBtn.hidden = !showToSee;
}

- (void)configWithInfo:(AWEInteractionLiveStickerInfoModel *)liveInfo
{
    [self updateUI:liveInfo];
    
    _liveInfo = liveInfo;
    [self updateTime];
    CGSize targetSize = [self liveStickerSize];
    if (!CGSizeEqualToSize(self.bounds.size, targetSize)) {
        self.bounds = CGRectMake(0.f, 0.f, targetSize.width, targetSize.height);
        ACCBLOCK_INVOKE(self.coordinateDidChange);
    }
}

- (void)changeResponderStatus:(BOOL)responder
{
    self.responder = responder;
}

- (void)clickToSeeBtn
{
    ACCBLOCK_INVOKE(self.clickOnToSeeBtn);
}

- (CGSize)liveStickerSize
{
    return self.liveInfo.showToSee || self.style != ACCLiveStickerViewStyleDefault ? CGSizeMake(104.f, 81.f) : CGSizeMake(88.f, 75.f);
}

- (CGRect)wantToSeeBtnFrame
{
    return CGRectInset(self.toSeeBtn.frame, -16.f, -14.f);
}

- (void)updateTime
{
    NSUInteger targetTime = self.liveInfo.targetTime;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSDate *targetDate = [NSDate dateWithTimeIntervalSince1970:targetTime];
    
    if ([self.liveInfo liveTimeValid]) {
        formatter.dateFormat = @"MM/dd HH:mm EEE";
        NSString *result = [formatter stringFromDate:targetDate];
        NSArray *results = [result componentsSeparatedByString:@" "];
        NSString *prefix = @"";
        
        NSCalendar *calendar = [NSCalendar currentCalendar];
        if ([calendar isDateInToday:targetDate]) {
            prefix = @"今天";
        } else if ([calendar isDateInTomorrow:targetDate]) {
            prefix = @"明天";
        } else if ([calendar isDateInTomorrow:[NSDate dateWithTimeIntervalSince1970:targetTime - 86400]]) {
            prefix = @"后天";
        }
        
        if (results.count >= 3) {
            if (prefix.length) {
                self.dateLabel.text = [NSString stringWithFormat:@"%@ %@", prefix, results[0]];
            } else {
                NSString *weekStr = results[2];
                if (weekStr.length) {
                    self.dateLabel.text = [NSString stringWithFormat:@"%@ %@", weekStr, results[0]];
                } else {
                    self.dateLabel.text = results[0];
                }
            }
            self.timeLabel.text = results[1];
        } else {
            self.dateLabel.text = result;
            self.timeLabel.text = @"";
        }
    } else {
        formatter.dateFormat = @"MM/dd HH:mm";
        NSString *result = [formatter stringFromDate:targetDate];
        self.dateLabel.text = result;
        if (self.liveInfo.status == ACCLiveStickerViewStatusEnd) {
            self.timeLabel.text = @"已完播";
        } else if (self.liveInfo.status == ACCLiveStickerViewStatusTimeout) {
            self.timeLabel.text = self.style != ACCLiveStickerViewStyleDefault ? @"已完播" : @"已过期";
        } else {
            self.timeLabel.text = @"";
        }
    }
}

#pragma mark - ACCStickerEditContentProtocol
- (void)setTransparent:(BOOL)transparent
{
    _transparent = transparent;
    self.alpha = transparent? 0.5: 1.0;
}

- (BOOL)canBecomeFirstResponder
{
    return self.responder;
}

- (BOOL)canResignFirstResponder
{
    return self.responder;
}

#pragma mark - transport
- (void)transportToEditWithSuperView:(UIView *)superView
                   animationDuration:(CGFloat)duration
                           animation:(void (^)(void))animationBlock
                          completion:(void (^)(void))completion
{
    CGPoint center = [self.superview convertPoint:self.center toView:superView];
    CGAffineTransform transform = self.superview.transform;
    [self removeFromSuperview];
    [superView addSubview:self];
    self.center = center;
    self.transform = transform;

    [UIView animateWithDuration:duration animations:^{
        self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.25, 1.25);
        self.acc_centerX = superView.acc_width * 0.5;
        self.acc_bottom = superView.acc_height * (ACC_SCREEN_HEIGHT < 667.f ? 0.32 : 0.4);
        ACCBLOCK_INVOKE(self.coordinateDidChange);
        ACCBLOCK_INVOKE(animationBlock);
    } completion:^(BOOL finished) {
        ACCBLOCK_INVOKE(completion);
    }];
}

- (void)restoreToSuperView:(UIView *)superView
         animationDuration:(CGFloat)duration
            animationBlock:(void (^)(void))animationBlock
                completion:(void (^)(void))completion
{
    CGPoint center = [self.superview convertPoint:self.center toView:superView];
    CGAffineTransform transform = superView.transform;
    transform = CGAffineTransformInvert(transform);
    [self removeFromSuperview];
    [superView addSubview:self];
    self.center = center;
    self.transform = transform;

    [UIView animateWithDuration:duration animations:^{
        self.transform = CGAffineTransformIdentity;
        self.center = CGPointMake(superView.bounds.size.width * 0.5, superView.bounds.size.height * 0.5);
        ACCBLOCK_INVOKE(animationBlock);
    } completion:^(BOOL finished) {
        ACCBLOCK_INVOKE(completion);
    }];
}

@end
