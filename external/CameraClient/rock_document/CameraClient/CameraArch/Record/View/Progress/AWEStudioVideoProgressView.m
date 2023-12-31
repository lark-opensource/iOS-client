//
//  AWEStudioVideoProgressView.m
//  Pods
//
//  Created by homeboy on 2019/4/26.
//

#import "AWEStudioVideoProgressView.h"
#import <CreationKitInfra/UILabel+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCRTL.h>
#import <CreativeKit/ACCFontProtocol.h>
#import "HTSVideoProgressView.h"
#import <CreativeKit/UIColor+CameraClientResource.h>

static NSString *const kAWEStudioVideoProgressTintColor = @"awe.studio.video.progress.tint.color";

@interface AWEStudioVideoProgressView ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *standardDurationLabel;
@property (nonatomic, strong) HTSVideoProgressView *progressView;
@property (nonatomic, assign, readwrite) float progress;

@end

@implementation AWEStudioVideoProgressView

@dynamic trackTintColor;
@synthesize originTrackTintColor = _originTrackTintColor;

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.accrtl_viewType = ACCRTLViewTypeNormalWithAllDescendants;
    self.containerView = [UIView new];
    self.containerView.backgroundColor = UIColor.clearColor;
    self.containerView.frame = CGRectMake(8, 0, self.bounds.size.width - 16, 6);
    self.containerView.layer.cornerRadius = 3;
    self.containerView.clipsToBounds = YES;
    [self addSubview:self.containerView];
    self.progressView = [[HTSVideoProgressView alloc] init];
    self.progressView.accrtl_viewType = ACCRTLViewTypeNormal;
    self.progressView.isRightEnd = YES;
    self.progressView.isLeftEnd = YES;
    self.progressView.rounded = NO;
    self.progressView.frame = CGRectMake(0, 0,  self.bounds.size.width - 16, 6);
    [self.containerView addSubview:self.progressView];
    self.progressView.progressTintColor = ACCResourceColor(kAWEStudioVideoProgressTintColor);
    _originTrackTintColor = self.progressView.trackTintColor = ACCResourceColor(ACCUIColorConstSDInverse);
    self.progressView.tintColor = ACCResourceColor(ACCUIColorConstTextInverse);
    
    // 长视频提示
    self.standardDurationLabel = [[UILabel alloc] init];
    self.standardDurationLabel.accrtl_viewType = ACCRTLViewTypeNormal;
    self.standardDurationLabel.text = @"15s";
    self.standardDurationLabel.font = [ACCFont() systemFontOfSize:12.0 weight:ACCFontWeightMedium];
    self.standardDurationLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
    [self.standardDurationLabel acc_addShadowWithShadowColor:ACCResourceColor(ACCUIColorConstLinePrimary) shadowOffset:CGSizeMake(0, 1) shadowRadius:2];
    self.standardDurationLabel.hidden = YES;
    self.standardDurationLabel.alpha = 0;
    [self.standardDurationLabel sizeToFit];
    [self addSubview:self.standardDurationLabel];
    
    self.progressView.standardDurationLabel = self.standardDurationLabel;
}

#pragma mark - Public

- (void)blinkMarkAtCurrentProgress:(BOOL)on
{
    [self.progressView blinkMarkAtCurrentProgress:on];
}

- (void)setProgress:(float)progress duration:(double)duration animated:(BOOL)animated {
    [self.progressView setProgress:progress duration:duration animated:animated];
    self.progress = progress;
}

- (void)updateViewWithProgress:(CGFloat)progress
                         marks:(NSArray *)marks
                      duration:(double)duration
                     totalTime:(CGFloat)totalTime
                      animated:(BOOL)animated{
    [self setProgress:progress duration:duration animated:animated];
    [self.progressView layoutSegments:marks toalTime:totalTime];
}


- (void)updateViewWithTimeSegments:(NSArray *)segments
                         totalTime:(CGFloat)totalTime {
    [self.progressView updateViewWithTimeSegments:segments totalTime:totalTime];
}

- (void)updateStandardDurationIndicatorWithLongVideoEnabled:(BOOL)longVideoEnabled
                                           standardDuration:(double)standardDuration
                                                maxDuration:(double)maxDuration {
    [self.progressView updateStandardDurationIndicatorWithLongVideoEnabled:longVideoEnabled
                                                          standardDuration:standardDuration
                                                               maxDuration:maxDuration];
}

#pragma mark - AWEVideoProgressViewColorState

- (UIColor *)trackTintColor
{
    return self.progressView.trackTintColor;
}

- (void)setTrackTintColor:(UIColor *)trackTintColor
{
    self.progressView.trackTintColor = trackTintColor;
}

@end
