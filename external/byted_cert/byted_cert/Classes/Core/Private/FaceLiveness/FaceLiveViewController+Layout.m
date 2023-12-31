//
//  FaceLiveViewController+Layout.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/25.
//

#import "FaceLiveViewController+Layout.h"
#import "BDCTAdditions.h"
#import "BDCTBiggerButton.h"
#import "BDCTLocalization.h"
#import "BDCTFlow.h"
#import "FaceLiveViewController+Audio.h"
#import "BytedCertManager+Private.h"

#import <objc/runtime.h>
#import <BDAssert/BDAssert.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import <Masonry/Masonry.h>

#define firstHalfInterpolation(t, s) (t * t * ((s + 1) * t - s))
#define secondHalfInterpolation(t, s) (t * t * ((s + 1) * t + s))


@implementation FaceLiveViewController (Layout)

- (UILabel *)topbarTitleLabel {
    UILabel *topbarTitleLabel = objc_getAssociatedObject(self, _cmd);
    if (!topbarTitleLabel) {
        topbarTitleLabel = [UILabel new];
        topbarTitleLabel.textAlignment = NSTextAlignmentCenter;
        topbarTitleLabel.font = [UIFont boldSystemFontOfSize:16];
        topbarTitleLabel.userInteractionEnabled = NO;
        topbarTitleLabel.textColor = BytedCertUIConfig.sharedInstance.textColor;
        [self.view addSubview:topbarTitleLabel];
        objc_setAssociatedObject(self, _cmd, topbarTitleLabel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return topbarTitleLabel;
}

- (UIButton *)backButton {
    UIButton *backButton = objc_getAssociatedObject(self, _cmd);
    if (!backButton) {
        backButton = [[BDCTBiggerButton alloc] initWithFrame:CGRectZero];
        [backButton setImage:[BytedCertUIConfig.sharedInstance.backBtnImage btd_ImageWithTintColor:BytedCertUIConfig.sharedInstance.textColor] forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(didTapNavBackButton) forControlEvents:UIControlEventTouchUpInside];
        [self.view insertSubview:backButton aboveSubview:self.mainWrapperView];
        objc_setAssociatedObject(self, _cmd, backButton, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return backButton;
}

- (UIButton *)audioSwitchButton {
    UIButton *audioSwitchButton = objc_getAssociatedObject(self, _cmd);
    if (!audioSwitchButton && self.audioPath) {
        audioSwitchButton = [[BDCTBiggerButton alloc] initWithFrame:CGRectZero];
        BOOL darkMode = [BytedCertUIConfig sharedInstance].isDarkMode;
        [audioSwitchButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@_%@", darkMode ? @"dark" : @"light", self.openAudio ? @"audio_open_switch" : @"audio_close_switch"] inBundle:[NSBundle bdct_bundle] compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
        [audioSwitchButton addTarget:self action:@selector(changeAudioSwitch) forControlEvents:UIControlEventTouchUpInside];
        [audioSwitchButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(20, 16));
        }];
        [self.view insertSubview:audioSwitchButton aboveSubview:self.mainWrapperView];
        objc_setAssociatedObject(self, _cmd, audioSwitchButton, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return audioSwitchButton;
}

- (UIImageView *)mainWrapperView {
    UIImageView *mainWrapperView = objc_getAssociatedObject(self, _cmd);
    if (!mainWrapperView) {
        mainWrapperView = [UIImageView new];
        mainWrapperView.userInteractionEnabled = YES;
        if (BytedCertUIConfig.sharedInstance.faceDetectionBgImage) {
            mainWrapperView.contentMode = UIViewContentModeScaleAspectFill;
            mainWrapperView.image = BytedCertUIConfig.sharedInstance.faceDetectionBgImage;
        }
        mainWrapperView.backgroundColor = BytedCertUIConfig.sharedInstance.backgroundColor ?: [UIColor whiteColor];
        [self.view addSubview:mainWrapperView];
        objc_setAssociatedObject(self, _cmd, mainWrapperView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return mainWrapperView;
}

- (UIView<BDCTCaptureRenderProtocol> *)captureRenderView {
    UIView<BDCTCaptureRenderProtocol> *captureRenderView = objc_getAssociatedObject(self, _cmd);
    if (!captureRenderView) {
        if (self.beautyIntensity > 0) {
            if (NSClassFromString(@"NewEffectPreview")) {
                captureRenderView = [NSClassFromString(@"NewEffectPreview") new];
                [captureRenderView setValue:@(self.beautyIntensity) forKey:@"beautyIntensity"];
            } else {
                BDAssert(NO, @"需依赖'beauty'子库");
                captureRenderView = [BDCTCaptureRenderView new];
            }
        } else {
            captureRenderView = [BDCTCaptureRenderView new];
        }
        [self.view insertSubview:captureRenderView atIndex:0];
        objc_setAssociatedObject(self, _cmd, captureRenderView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return captureRenderView;
}

- (UILabel *)actionTipLabel {
    UILabel *actionTipLabel = objc_getAssociatedObject(self, _cmd);
    if (!actionTipLabel) {
        actionTipLabel = [UILabel new];
        actionTipLabel.textAlignment = NSTextAlignmentCenter;
        actionTipLabel.minimumScaleFactor = 0.4f;
        actionTipLabel.numberOfLines = 1;
        actionTipLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        actionTipLabel.textColor = BytedCertUIConfig.sharedInstance.textColor;
        actionTipLabel.font = BytedCertUIConfig.sharedInstance.actionLabelFont ?: self.bdct_flow.context.liveDetectionOpt ? [UIFont fontWithName:@"PingFangSC-Medium" size:20] :
                                                                                                                            [UIFont boldSystemFontOfSize:26];
        actionTipLabel.adjustsFontSizeToFitWidth = YES;
        actionTipLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        [self.view insertSubview:actionTipLabel aboveSubview:self.mainWrapperView];
        objc_setAssociatedObject(self, _cmd, actionTipLabel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return actionTipLabel;
}

- (BDCTAlignLabel *)smallActionTipLabel {
    BDCTAlignLabel *smallActionTipLabel = objc_getAssociatedObject(self, _cmd);
    if (!smallActionTipLabel) {
        smallActionTipLabel = [BDCTAlignLabel new];
        [smallActionTipLabel setHidden:YES];
        smallActionTipLabel.textColor = UIColor.whiteColor;
        smallActionTipLabel.textAlignment = NSTextAlignmentCenter;
        smallActionTipLabel.minimumScaleFactor = 0.4f;
        smallActionTipLabel.numberOfLines = 1;
        smallActionTipLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
        [smallActionTipLabel setVerticalAlignment:VerticalAlignmentBottom];
        [smallActionTipLabel setFont:[UIFont fontWithName:@"PingFangSC-Semibold" size:16]];
        [self.view insertSubview:smallActionTipLabel belowSubview:self.mainWrapperView];
        objc_setAssociatedObject(self, _cmd, smallActionTipLabel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return smallActionTipLabel;
}

- (UILabel *)actionCountTipLabel {
    UILabel *actionCountTipLabel = objc_getAssociatedObject(self, _cmd);
    if (!actionCountTipLabel) {
        actionCountTipLabel = [UILabel new];
        actionCountTipLabel.textAlignment = NSTextAlignmentCenter;
        actionCountTipLabel.numberOfLines = 1;
        actionCountTipLabel.textColor = BytedCertUIConfig.sharedInstance.textColor;
        actionCountTipLabel.font = BytedCertUIConfig.sharedInstance.actionCountTipLabelFont;
        actionCountTipLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        objc_setAssociatedObject(self, _cmd, actionCountTipLabel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return actionCountTipLabel;
}

- (UIImageView *)trustWorthyLogo {
    UIImageView *trustWorthyLogo = objc_getAssociatedObject(self, _cmd);
    if (!trustWorthyLogo) {
        trustWorthyLogo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"trustworthy_logo" inBundle:[NSBundle bdct_bundle] compatibleWithTraitCollection:nil]];
        [trustWorthyLogo mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(12.01, 16));
        }];
        [self.view addSubview:trustWorthyLogo];
        objc_setAssociatedObject(self, _cmd, trustWorthyLogo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return trustWorthyLogo;
}

- (UIImageView *)inspectionCenterLogo {
    UIImageView *inspectionCenterLogo = objc_getAssociatedObject(self, _cmd);
    if (!inspectionCenterLogo) {
        inspectionCenterLogo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"inspection_center_logo" inBundle:[NSBundle bdct_bundle] compatibleWithTraitCollection:nil]];
        [inspectionCenterLogo mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(27.74, 20.12));
        }];
        [self.view addSubview:inspectionCenterLogo];
        objc_setAssociatedObject(self, _cmd, inspectionCenterLogo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return inspectionCenterLogo;
}

- (UILabel *)protectFaceLable {
    UILabel *protectFaceLable = objc_getAssociatedObject(self, _cmd);
    if (!protectFaceLable) {
        protectFaceLable = [UILabel new];
        protectFaceLable.numberOfLines = 1;
        protectFaceLable.text = @"本服务自研技术通过通信院等权威认证，保障信息安全";
        protectFaceLable.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        if (BytedCertUIConfig.sharedInstance.isDarkMode) {
            protectFaceLable.textColor = [UIColor btd_colorWithHexString:@"#FFFFFF" alpha:0.5];
        } else {
            protectFaceLable.textColor = [UIColor btd_colorWithHexString:@"#161823" alpha:0.6];
        }
        objc_setAssociatedObject(self, _cmd, protectFaceLable, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return protectFaceLable;
}

- (CAShapeLayer *)circleProgressBackgroundLayer {
    CAShapeLayer *circleProgressBackgroundLayer = objc_getAssociatedObject(self, _cmd);
    if (!circleProgressBackgroundLayer) {
        circleProgressBackgroundLayer = [CAShapeLayer layer];
        UIColor *circleBgColor = BytedCertUIConfig.sharedInstance.circleColor ?: BytedCertUIConfig.sharedInstance.secondBackgroundColor;
        circleProgressBackgroundLayer.strokeColor = circleBgColor.CGColor;
        circleProgressBackgroundLayer.fillColor = [UIColor clearColor].CGColor;
        circleProgressBackgroundLayer.lineWidth = BytedCertUIConfig.sharedInstance.faceDetectionProgressStrokeWidth;
        circleProgressBackgroundLayer.lineCap = kCALineCapRound;
        circleProgressBackgroundLayer.lineJoin = kCALineJoinRound;
        objc_setAssociatedObject(self, _cmd, circleProgressBackgroundLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return circleProgressBackgroundLayer;
}

- (CAShapeLayer *)circleProgressTrackLayer {
    CAShapeLayer *circleProgressTrackLayer = objc_getAssociatedObject(self, _cmd);
    if (!circleProgressTrackLayer) {
        circleProgressTrackLayer = [CAShapeLayer layer];
        UIColor *strokeColor = (BytedCertUIConfig.sharedInstance.timeColor ?: BytedCertUIConfig.sharedInstance.primaryColor) ?: [UIColor btd_colorWithHexString:@"#2A90D7"];
        circleProgressTrackLayer.strokeColor = strokeColor.CGColor;
        circleProgressTrackLayer.fillColor = [UIColor clearColor].CGColor;
        circleProgressTrackLayer.lineWidth = self.circleProgressBackgroundLayer.lineWidth;
        circleProgressTrackLayer.lineCap = kCALineCapRound;
        circleProgressTrackLayer.lineJoin = kCALineJoinRound;
        objc_setAssociatedObject(self, _cmd, circleProgressTrackLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return circleProgressTrackLayer;
}

- (CAShapeLayer *)outterCircleLayer {
    CAShapeLayer *outterCircleLayer = objc_getAssociatedObject(self, _cmd);
    if (!outterCircleLayer) {
        outterCircleLayer = [CAShapeLayer layer];
        UIColor *color = (BytedCertUIConfig.sharedInstance.timeColor ?: BytedCertUIConfig.sharedInstance.primaryColor) ?: [UIColor colorWithRed:254 green:44 blue:85 alpha:0.5];
        CGColorRef strokeColor = CGColorCreateCopyWithAlpha(color.CGColor, 0.5);
        outterCircleLayer.strokeColor = strokeColor;
        CFRelease(strokeColor);
        outterCircleLayer.fillColor = [UIColor clearColor].CGColor;
        outterCircleLayer.lineWidth = 2;
        outterCircleLayer.lineDashPhase = 1.0;
        outterCircleLayer.lineDashPattern = @[ @4, @4 ];
        objc_setAssociatedObject(self, _cmd, outterCircleLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return outterCircleLayer;
}

- (CAShapeLayer *)innerCircleLayer {
    CAShapeLayer *innerCircleLayer = objc_getAssociatedObject(self, _cmd);
    if (!innerCircleLayer) {
        innerCircleLayer = [CAShapeLayer layer];
        UIColor *color = (BytedCertUIConfig.sharedInstance.timeColor ?: BytedCertUIConfig.sharedInstance.primaryColor) ?: [UIColor colorWithRed:254 green:44 blue:85 alpha:0.5];
        CGColorRef strokeColor = CGColorCreateCopyWithAlpha(color.CGColor, 0.5);
        innerCircleLayer.strokeColor = strokeColor;
        CFRelease(strokeColor);
        innerCircleLayer.fillColor = [UIColor clearColor].CGColor;
        innerCircleLayer.lineWidth = 2;
        objc_setAssociatedObject(self, _cmd, innerCircleLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return innerCircleLayer;
}

- (CAShapeLayer *)outterArcLayer {
    CAShapeLayer *outterArcLayer = objc_getAssociatedObject(self, _cmd);
    if (!outterArcLayer) {
        outterArcLayer = [CAShapeLayer layer];
        UIColor *color = (BytedCertUIConfig.sharedInstance.timeColor ?: BytedCertUIConfig.sharedInstance.primaryColor) ?: [UIColor colorWithRed:254 green:44 blue:85 alpha:0.5];
        CGColorRef strokeColor = CGColorCreateCopyWithAlpha(color.CGColor, 0.5);
        outterArcLayer.strokeColor = strokeColor;
        CFRelease(strokeColor);
        outterArcLayer.fillColor = [UIColor clearColor].CGColor;
        outterArcLayer.lineWidth = 4;
        objc_setAssociatedObject(self, _cmd, outterArcLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return outterArcLayer;
}

- (CAShapeLayer *)innerArcLayer {
    CAShapeLayer *innerArcLayer = objc_getAssociatedObject(self, _cmd);
    if (!innerArcLayer) {
        innerArcLayer = [CAShapeLayer layer];
        UIColor *color = (BytedCertUIConfig.sharedInstance.timeColor ?: BytedCertUIConfig.sharedInstance.primaryColor) ?: [UIColor colorWithRed:254 green:44 blue:85 alpha:0.5];
        CGColorRef strokeColor = CGColorCreateCopyWithAlpha(color.CGColor, 0.5);
        innerArcLayer.strokeColor = strokeColor;
        CFRelease(strokeColor);
        innerArcLayer.fillColor = [UIColor clearColor].CGColor;
        innerArcLayer.lineWidth = 4;
        objc_setAssociatedObject(self, _cmd, innerArcLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return innerArcLayer;
}

- (double)beginTime {
    NSNumber *beginTime = objc_getAssociatedObject(self, _cmd);
    if (!beginTime) {
        beginTime = @(CACurrentMediaTime());
        objc_setAssociatedObject(self, _cmd, beginTime, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return beginTime.doubleValue;
}

- (CADisplayLink *)displayLink {
    CADisplayLink *displayLink = objc_getAssociatedObject(self, _cmd);
    if (!displayLink) {
        displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onDisplayLink:)];
    }
    return displayLink;
}

- (CGRect)cropCircleRect {
    return [objc_getAssociatedObject(self, _cmd) CGRectValue];
}

- (void)setCropCircleRect:(CGRect)cropCircleRect {
    objc_setAssociatedObject(self, @selector(cropCircleRect), [NSValue valueWithCGRect:cropCircleRect], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)layoutContentViews {
    if (CGRectEqualToRect(self.mainWrapperView.frame, self.view.bounds)) {
        return;
    }
    self.view.backgroundColor = UIColor.blackColor;
    self.mainWrapperView.frame = self.view.bounds;
    CGFloat statusbarHeight = UIApplication.sharedApplication.statusBarFrame.size.height;
    // 适配iPad的弹窗样式
    if ([self.view convertRect:self.view.bounds toView:nil].origin.y > 0) {
        statusbarHeight = 0;
    }
    self.backButton.frame = CGRectMake(15, statusbarHeight, 44, 44);
    [self.audioSwitchButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.mainWrapperView.mas_right).mas_offset(-20);
        make.top.mas_equalTo(self.mainWrapperView.mas_top).mas_offset(statusbarHeight);
    }];
    // 圆框
    CGFloat cropCircleWidth = MIN(self.view.bounds.size.width * 0.7f, self.view.bounds.size.height * 0.5);
    if (self.bdct_flow.context.liveDetectionOpt) {
        self.cropCircleRect = CGRectMake(self.mainWrapperView.center.x - cropCircleWidth / 2.0, self.mainWrapperView.center.y - cropCircleWidth / 2.0, cropCircleWidth, cropCircleWidth);

        //动作提示
        if (!self.actionTipLabel.text.length) {
            [self.actionTipLabel setText:@" "];
        }
        [self.actionTipLabel sizeToFit];
        self.actionTipLabel.frame = CGRectMake(15, self.cropCircleRect.origin.y - 50, self.view.frame.size.width - 30, self.actionTipLabel.bounds.size.height);
    } else {
        // 动作提示
        if (!self.actionTipLabel.text.length) {
            [self.actionTipLabel setText:@" "];
        }
        [self.actionTipLabel sizeToFit];
        self.actionTipLabel.frame = CGRectMake(15, CGRectGetMaxY(self.backButton.frame) + 60, self.view.frame.size.width - 30, self.actionTipLabel.bounds.size.height);

        self.cropCircleRect = CGRectMake(self.mainWrapperView.center.x - cropCircleWidth / 2.0, CGRectGetMaxY(self.actionTipLabel.frame) + 32, cropCircleWidth, cropCircleWidth);
    }

    UIBezierPath *bpath = [UIBezierPath bezierPathWithRoundedRect:self.mainWrapperView.bounds cornerRadius:0];
    [bpath appendPath:[UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetMidX(self.cropCircleRect), CGRectGetMidY(self.cropCircleRect)) radius:(cropCircleWidth / 2.0) startAngle:0 endAngle:2 * M_PI clockwise:NO]];
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = bpath.CGPath;
    self.mainWrapperView.layer.mask = shapeLayer;

    // 预览
    self.captureRenderView.frame = self.view.bounds;
    [self updateLivenessMaskRadiusRatio];

    // 圆内动作提示
    if (!self.smallActionTipLabel.text.length) {
        [self.smallActionTipLabel setText:@" "];
    }
    [self.smallActionTipLabel sizeToFit];
    self.smallActionTipLabel.frame = CGRectMake(0, self.cropCircleRect.origin.y, self.view.frame.size.width, self.smallActionTipLabel.bounds.size.height + 1 * 2);
    [self addliveDetectAnimation];
    self.topbarTitleLabel.text = self.title;
    self.topbarTitleLabel.frame = CGRectMake(0, UIApplication.sharedApplication.statusBarFrame.size.height, self.view.bounds.size.width, 44);
    if (self.bdct_flow.context.liveDetectionOpt) {
        [self.view addSubview:self.actionCountTipLabel];
        [self.actionCountTipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.mas_equalTo(self.view);
            make.top.mas_equalTo(self.cropCircleRect.origin.y + self.cropCircleRect.size.height + 24);
            make.width.mas_equalTo(240);
            make.height.mas_equalTo(28);
        }];
    }
    if (self.bdct_flow.context.showProtectFaceLogo) {
        [self.protectFaceLable sizeToFit];
        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[ self.trustWorthyLogo, self.inspectionCenterLogo, self.protectFaceLable ]];
        stackView.alignment = UIStackViewAlignmentCenter;
        stackView.axis = UILayoutConstraintAxisHorizontal;
        stackView.spacing = 1;
        [self.view addSubview:stackView];
        [stackView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.view);
            make.height.mas_equalTo(44);
            if (@available(iOS 11.0, *)) {
                make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-10);
            } else {
                make.bottom.equalTo(self.view).offset(-10);
            }
        }];
    }
}

- (void)layoutPreviewIfNeededWithPixelBufferSize:(CGSize)pixelBufferSize {
    if (!pixelBufferSize.width || !pixelBufferSize.height) {
        return;
    }

    CGFloat previewWidth = self.cropCircleRect.size.width + 2;
    CGFloat previewHeight = self.cropCircleRect.size.width + 2;
    if (pixelBufferSize.height > pixelBufferSize.width) {
        previewHeight = previewWidth * (pixelBufferSize.height / pixelBufferSize.width);
    } else {
        previewWidth = previewHeight * (pixelBufferSize.width / pixelBufferSize.height);
    }
    if (CGSizeEqualToSize(CGSizeMake(previewWidth, previewHeight), self.captureRenderView.bounds.size)) {
        return;
    }
    self.captureRenderView.frame = CGRectMake(0, 0, previewWidth, previewHeight);
    self.captureRenderView.center = CGPointMake(CGRectGetMidX(self.cropCircleRect), CGRectGetMidY(self.cropCircleRect));
    [self updateLivenessMaskRadiusRatio];
}

- (void)showContinueAlertWithDismissBlock:(void (^)(BOOL cancel))dissmissBlock {
    UIView *alertBgView = [[UIView alloc] initWithFrame:self.view.frame];
    alertBgView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    [self.view addSubview:alertBgView];
    UIAlertController *alertControlelr = [UIAlertController alertControllerWithTitle:@"退出提醒" message:@"即将退出认证流程，退出后可能影响部分功能的使用，是否继续认证?" preferredStyle:UIAlertControllerStyleAlert];
    [alertControlelr addAction:[UIAlertAction actionWithTitle:@"取消认证" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
                         [alertBgView removeFromSuperview];
                         !dissmissBlock ?: dissmissBlock(YES);
                     }]];
    [alertControlelr addAction:[UIAlertAction actionWithTitle:@"继续认证" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
                         [alertBgView removeFromSuperview];
                         !dissmissBlock ?: dissmissBlock(NO);
                     }]];
    [alertControlelr bdct_showFromViewController:self];
}

- (void)addliveDetectAnimation {
    if (![self.bdct_flow.context.finalLivenessType isEqualToString:BytedCertLiveTypeVideo]) {
        UIBezierPath *bezierPath;
        if ([self.bdct_flow.context.finalLivenessType isEqualToString:BytedCertLiveTypeQuality] || [self.bdct_flow.context.finalLivenessType isEqualToString:BytedCertLiveTypeStill]) {
            bezierPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetMidX(self.cropCircleRect), CGRectGetMidY(self.cropCircleRect)) radius:self.cropCircleRect.size.width / 2.0 + BytedCertUIConfig.sharedInstance.faceDetectionProgressStrokeWidth * 1.5 startAngle:(M_PI / 2 + M_PI / 4) endAngle:(M_PI / 2 - M_PI / 4) clockwise:YES];
            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
            self.circleProgressTrackLayer.strokeEnd = 0;
            [CATransaction commit];
        } else {
            if (self.bdct_flow.context.liveDetectionOpt && [self.bdct_flow.context.finalLivenessType isEqualToString:BytedCertLiveTypeAction]) {
                CGPoint center = CGPointMake(CGRectGetMidX(self.cropCircleRect), CGRectGetMidY(self.cropCircleRect));
                CGFloat innerRadius = self.cropCircleRect.size.width / 2.0 + 5;
                CGFloat outerRadius = self.cropCircleRect.size.width / 2.0 + 15;
                CGFloat startAngle = -M_PI / 6;
                CGFloat endAngle = M_PI / 2 + M_PI / 3;
                UIBezierPath *innerCirclePath = [UIBezierPath bezierPathWithArcCenter:center radius:innerRadius startAngle:startAngle endAngle:endAngle clockwise:YES];
                self.innerCircleLayer.path = innerCirclePath.CGPath;
                UIBezierPath *outterCirclePath = [UIBezierPath bezierPathWithArcCenter:center radius:outerRadius startAngle:startAngle endAngle:endAngle clockwise:NO];
                self.outterCircleLayer.path = outterCirclePath.CGPath;

                UIBezierPath *innerArcPath = [UIBezierPath bezierPathWithArcCenter:center radius:innerRadius startAngle:startAngle endAngle:endAngle clockwise:NO];
                self.innerArcLayer.path = innerArcPath.CGPath;

                UIBezierPath *outterArcPath = [UIBezierPath bezierPathWithArcCenter:center radius:outerRadius startAngle:startAngle endAngle:endAngle clockwise:YES];
                self.outterArcLayer.path = outterArcPath.CGPath;

                [self.mainWrapperView.layer addSublayer:self.innerCircleLayer];
                [self.mainWrapperView.layer addSublayer:self.outterCircleLayer];
                [self.mainWrapperView.layer addSublayer:self.innerArcLayer];
                [self.mainWrapperView.layer addSublayer:self.outterArcLayer];


                [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
            } else {
                bezierPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetMidX(self.cropCircleRect), CGRectGetMidY(self.cropCircleRect)) radius:self.cropCircleRect.size.width / 2.0 + BytedCertUIConfig.sharedInstance.faceDetectionProgressStrokeWidth * 1.5 startAngle:(M_PI / 2 - M_PI / 4) endAngle:(M_PI / 2 + M_PI / 4) clockwise:NO];
            }
        }
        if (!self.bdct_flow.context.liveDetectionOpt) {
            self.circleProgressBackgroundLayer.path = bezierPath.CGPath;
            self.circleProgressTrackLayer.path = self.circleProgressBackgroundLayer.path;

            [self.mainWrapperView.layer addSublayer:self.circleProgressBackgroundLayer];
            [self.mainWrapperView.layer addSublayer:self.circleProgressTrackLayer];
        }
    }
}

- (void)onDisplayLink:(CADisplayLink *)displayLink {
    CGFloat rotatePercent = 0;
    CGFloat currentTime = fmod((CACurrentMediaTime() - self.beginTime), 8.0);
    CGFloat timePercent = currentTime / 8.0;

    if (timePercent < 0.5) {
        rotatePercent = 0.5 * firstHalfInterpolation((timePercent * 2.0), 2);
    } else {
        rotatePercent = 0.5 * (secondHalfInterpolation((timePercent * 2.0 - 2), 2) + 2.0);
    }

    CGFloat rotateAngle = rotatePercent * 2 * M_PI;
    UIBezierPath *innerCirclePath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetMidX(self.cropCircleRect), CGRectGetMidY(self.cropCircleRect)) radius:self.cropCircleRect.size.width / 2.0 + 5 startAngle:(-M_PI / 6) - rotateAngle endAngle:(M_PI / 2 + M_PI / 3) - rotateAngle clockwise:YES];
    self.innerCircleLayer.path = innerCirclePath.CGPath;

    UIBezierPath *innerArcPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetMidX(self.cropCircleRect), CGRectGetMidY(self.cropCircleRect)) radius:self.cropCircleRect.size.width / 2.0 + 5 startAngle:(-M_PI / 6) - rotateAngle endAngle:(M_PI / 2 + M_PI / 3) - rotateAngle clockwise:NO];
    self.innerArcLayer.path = innerArcPath.CGPath;

    UIBezierPath *outterCirclePath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetMidX(self.cropCircleRect), CGRectGetMidY(self.cropCircleRect)) radius:self.cropCircleRect.size.width / 2.0 + 15 startAngle:(-M_PI / 6) + rotateAngle endAngle:(M_PI / 2 + M_PI / 3) + rotateAngle clockwise:NO];
    self.outterCircleLayer.path = outterCirclePath.CGPath;

    UIBezierPath *outterArcPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetMidX(self.cropCircleRect), CGRectGetMidY(self.cropCircleRect)) radius:self.cropCircleRect.size.width / 2.0 + 15 startAngle:(-M_PI / 6) + rotateAngle endAngle:(M_PI / 2 + M_PI / 3) + rotateAngle clockwise:YES];
    self.outterArcLayer.path = outterArcPath.CGPath;
}

#pragma mark - Actions

- (void)changeAudioSwitch {
    BOOL darkMode = [BytedCertUIConfig sharedInstance].isDarkMode;
    [self.audioSwitchButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@_%@", darkMode ? @"dark" : @"light", self.openAudio ? @"audio_close_switch" : @"audio_open_switch"] inBundle:[NSBundle bdct_bundle] compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    self.openAudio = !self.openAudio;
    self.bdct_flow.context.voiceGuideUser = self.openAudio;
}

@end
