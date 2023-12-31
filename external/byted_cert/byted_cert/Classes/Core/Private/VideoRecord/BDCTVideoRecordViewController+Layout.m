//
//  BDCTVideoRecordViewController+Layout.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/16.
//

#import "BDCTVideoRecordViewController+Layout.h"
#import "BDCTVideoRecordViewController+Camera.h"
#import "UIViewController+BDCTAdditions.h"
#import "UIImage+BDCTAdditions.h"
#import "BDCTLocalization.h"
#import "BDCTVideoRecordPreviewViewController.h"
#import "BytedCertUIConfig.h"
#import "BDCTFlow.h"
#import "BDCTFlowContext.h"

#import <ByteDanceKit/UIButton+BTDAdditions.h>
#import <ByteDanceKit/UIImage+BTDAdditions.h>
#import <ByteDanceKit/UIView+BTDAdditions.h>
#import <ByteDanceKit/UIColor+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>
#import <Masonry/Masonry.h>
#import <objc/runtime.h>

static const CGFloat kBDCTVideRecordContentTextLineSpace = 10.f;


@implementation BDCTVideoRecordViewController (Layout)

- (NSAttributedString *)attributedContentStringWithHighLigthLength:(int)highLigthLength {
    NSString *text = ((BytedCertVideoRecordParameter *)self.bdct_flow.context.parameter).readText ?: @"";
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:text];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:kBDCTVideRecordContentTextLineSpace];
    [mutableAttributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, text.length)];
    highLigthLength = MAX(0, MIN(highLigthLength, (int)text.length));
    [mutableAttributedString addAttribute:NSForegroundColorAttributeName value:[UIColor btd_colorWithHexString:@"#FACE15"] range:NSMakeRange(0, highLigthLength)];
    return mutableAttributedString.copy;
}

- (UIView *)maskView {
    return objc_getAssociatedObject(self, _cmd);
}

- (UILabel *)startCountDownLabel {
    return objc_getAssociatedObject(self, _cmd);
}

- (UIButton *)retryBtn {
    return objc_getAssociatedObject(self, _cmd);
}

- (UILabel *)contentLabel {
    return objc_getAssociatedObject(self, _cmd);
}

- (UILabel *)fakeContentLabel {
    return objc_getAssociatedObject(self, _cmd);
}

- (CGRect)recordFaceRect {
    return [objc_getAssociatedObject(self, _cmd) CGRectValue];
}

- (UILabel *)faceQualityLabel {
    return objc_getAssociatedObject(self, _cmd);
}

- (BOOL)relayoutContentViewsIfNeeded {
    if (!CGRectEqualToRect(self.view.bounds, [self maskView].frame)) {
        [self layoutContentViews];
        return YES;
    }
    return NO;
}

- (void)layoutContentViews {
    [self.view btd_removeAllSubviews];

    self.view.backgroundColor = UIColor.blackColor;

    UIView *maskView = [UIView new];
    maskView.frame = self.view.bounds;
    [self.view addSubview:maskView];
    objc_setAssociatedObject(self, @selector(maskView), maskView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    UIButton *navBackBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    navBackBtn.frame = CGRectMake(5, UIApplication.sharedApplication.statusBarFrame.size.height, 44, 44);
    [navBackBtn setImage:[BytedCertUIConfig.sharedInstance.backBtnImage btd_ImageWithTintColor:UIColor.whiteColor] forState:UIControlStateNormal];
    @weakify(self);
    [navBackBtn btd_addActionBlockForTouchUpInside:^(__kindof UIButton *_Nonnull sender) {
        @strongify(self);
        [self didTapNavBackButton];
    }];
    [self.view addSubview:navBackBtn];

    UILabel *titleLabel = [UILabel new];
    [titleLabel setText:BytedCertLocalizedString(@"用普通话匀速朗读如下文字")];
    [titleLabel setTextColor:[UIColor colorWithWhite:1 alpha:0.5]];
    [titleLabel setFont:[UIFont systemFontOfSize:13]];
    [titleLabel sizeToFit];
    titleLabel.btd_top = CGRectGetMaxY(navBackBtn.frame) + 8;
    titleLabel.btd_centerX = self.view.btd_centerX;
    [self.view addSubview:titleLabel];

    UILabel *contentLabel = [UILabel new];
    objc_setAssociatedObject(self, @selector(contentLabel), contentLabel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [contentLabel setNumberOfLines:0];
    [contentLabel setAttributedText:[self attributedContentStringWithHighLigthLength:0]];
    [contentLabel setTextColor:[UIColor whiteColor]];
    [contentLabel setFont:[UIFont systemFontOfSize:15]];
    CGSize textSize = [contentLabel sizeThatFits:CGSizeMake(self.view.bounds.size.width - 24 * 2, CGFLOAT_MAX)];

    UILabel *fakeContentLabel = [UILabel new];
    fakeContentLabel.numberOfLines = contentLabel.numberOfLines;
    fakeContentLabel.font = contentLabel.font;
    fakeContentLabel.alpha = 0.f;
    objc_setAssociatedObject(self, @selector(fakeContentLabel), fakeContentLabel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    int maxDisplayLineCount = 3;
    CGFloat maxContentDisplayHeight = (contentLabel.font.lineHeight + kBDCTVideRecordContentTextLineSpace) * maxDisplayLineCount - kBDCTVideRecordContentTextLineSpace;
    CGFloat displayHeight = MIN(maxContentDisplayHeight, textSize.height);

    UIView *contentLabelWrapperView = [UIView new];
    [contentLabelWrapperView.layer setMasksToBounds:YES];
    contentLabelWrapperView.btd_top = CGRectGetMaxY(titleLabel.frame) + 12;
    contentLabelWrapperView.btd_width = textSize.width;
    contentLabelWrapperView.btd_height = displayHeight;
    contentLabelWrapperView.btd_centerX = self.view.btd_centerX;
    [self.view addSubview:contentLabelWrapperView];

    [contentLabelWrapperView addSubview:contentLabel];
    contentLabel.btd_x = contentLabel.btd_y = 0;
    contentLabel.btd_width = contentLabelWrapperView.btd_width;
    contentLabel.btd_height = textSize.height;

    if (contentLabel.btd_height > contentLabelWrapperView.btd_height) {
        CAGradientLayer *gradientLayer = [CAGradientLayer new];
        gradientLayer.frame = CGRectMake(0, 0, contentLabelWrapperView.btd_width, contentLabelWrapperView.btd_height - contentLabel.font.lineHeight / 2.0);
        [gradientLayer setColors:@[ (__bridge id)[UIColor whiteColor].CGColor, (__bridge id)[UIColor clearColor].CGColor ]];
        [gradientLayer setStartPoint:CGPointMake(0.5, 0.8)];
        [gradientLayer setEndPoint:CGPointMake(0.5, 1.0)];
        contentLabelWrapperView.layer.mask = gradientLayer;
    }

    UIButton *reTryBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [reTryBtn setTitle:BytedCertLocalizedString(@"开始拍摄") forState:UIControlStateNormal];
    [reTryBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    reTryBtn.titleLabel.font = [UIFont systemFontOfSize:15 weight:500];
    reTryBtn.backgroundColor = [UIColor btd_colorWithHexString:@"#FE2C55"];
    reTryBtn.layer.cornerRadius = 4;
    [reTryBtn.layer setMasksToBounds:YES];
    reTryBtn.btd_width = self.view.btd_width - 16 * 2;
    reTryBtn.btd_height = 44;
    if (@available(iOS 11.0, *)) {
        reTryBtn.btd_bottom = (self.view.btd_height - (UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom + 15));
    } else {
        reTryBtn.btd_bottom = self.view.btd_height - 15;
    }
    reTryBtn.btd_centerX = self.view.btd_centerX;
    [reTryBtn btd_addActionBlockForTouchUpInside:^(__kindof UIButton *_Nonnull sender) {
        @strongify(self);
        [self startVideoRecord];
    }];
    [self.view addSubview:reTryBtn];
    objc_setAssociatedObject(self, @selector(retryBtn), reTryBtn, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    CGFloat recordRectTop = CGRectGetMaxY(contentLabelWrapperView.frame) + 20;
    CGFloat recordRectWidth = MIN(self.view.btd_width, self.view.btd_height) - 60 * 2;
    CGFloat w2hRatio = 255.0 / 330.0;
    CGFloat recordRectHeight = recordRectWidth / w2hRatio;
    if (recordRectTop + recordRectHeight > reTryBtn.btd_top - 44 - 14 - reTryBtn.btd_height) {
        recordRectHeight = reTryBtn.btd_top - 44 - 14 - reTryBtn.btd_height - recordRectTop;
        recordRectWidth = recordRectHeight * w2hRatio;
    }
    CGRect recordRect = CGRectMake((self.view.btd_width - recordRectWidth) / 2.0, recordRectTop, recordRectWidth, recordRectHeight);
    objc_setAssociatedObject(self, @selector(recordFaceRect), [NSValue valueWithCGRect:recordRect], OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:maskView.bounds cornerRadius:0];
    [bezierPath appendPath:[[UIBezierPath bezierPathWithRoundedRect:recordRect cornerRadius:20] bezierPathByReversingPath]];
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.fillColor = [UIColor colorWithWhite:0 alpha:0.8].CGColor;
    shapeLayer.path = bezierPath.CGPath;
    [maskView.layer addSublayer:shapeLayer];

    bezierPath = [UIBezierPath bezierPathWithRoundedRect:recordRect cornerRadius:20.f];
    shapeLayer = [CAShapeLayer layer];
    shapeLayer.lineWidth = 2;
    shapeLayer.strokeColor = [UIColor whiteColor].CGColor;
    shapeLayer.fillColor = [UIColor clearColor].CGColor;
    shapeLayer.path = bezierPath.CGPath;
    [maskView.layer addSublayer:shapeLayer];

    bezierPath = [[UIBezierPath bezierPathWithRect:CGRectMake(0, recordRect.origin.y + 60, maskView.btd_width, recordRect.size.height - 60 * 2)] bezierPathByReversingPath];
    [bezierPath appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake(60 + recordRect.origin.x, 0, recordRect.size.width - 60 * 2, maskView.btd_height)] bezierPathByReversingPath]];
    [bezierPath appendPath:[UIBezierPath bezierPathWithRect:maskView.bounds]];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.fillColor = [UIColor redColor].CGColor;
    maskLayer.path = bezierPath.CGPath;
    shapeLayer.mask = maskLayer;

    UILabel *startCountDownLabel = [UILabel new];
    startCountDownLabel.textAlignment = NSTextAlignmentCenter;
    startCountDownLabel.numberOfLines = 0;
    startCountDownLabel.textColor = UIColor.whiteColor;
    startCountDownLabel.font = [UIFont boldSystemFontOfSize:120];
    startCountDownLabel.frame = recordRect;
    [self.view addSubview:startCountDownLabel];
    objc_setAssociatedObject(self, @selector(startCountDownLabel), startCountDownLabel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    UILabel *tipLabel = [UILabel new];
    [tipLabel setText:BytedCertLocalizedString(@"请确认由本人亲自操作，将脸置于提示框内")];
    [tipLabel setTextColor:[UIColor colorWithWhite:1 alpha:0.5]];
    [tipLabel setFont:[UIFont systemFontOfSize:13]];
    [tipLabel sizeToFit];
    tipLabel.btd_top = CGRectGetMaxY(recordRect) + 20;
    tipLabel.btd_centerX = self.view.btd_centerX;
    [self.view addSubview:tipLabel];

    UILabel *faceQualityLabel = [[UILabel alloc] initWithFrame:recordRect];
    [faceQualityLabel setHidden:YES];
    faceQualityLabel.btd_height = 12 * 2 + 14;
    faceQualityLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    faceQualityLabel.textColor = UIColor.whiteColor;
    faceQualityLabel.font = [UIFont systemFontOfSize:14];
    faceQualityLabel.textAlignment = NSTextAlignmentCenter;
    [self.view insertSubview:faceQualityLabel belowSubview:maskView];

    bezierPath = [UIBezierPath bezierPathWithRoundedRect:faceQualityLabel.bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:(CGSize){20.0}];
    maskLayer = [CAShapeLayer layer];
    maskLayer.fillColor = [UIColor blackColor].CGColor;
    maskLayer.path = bezierPath.CGPath;
    faceQualityLabel.layer.mask = maskLayer;
    objc_setAssociatedObject(self, @selector(faceQualityLabel), faceQualityLabel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)updateFaceQualityText:(NSString *)text {
    self.faceQualityLabel.text = text ?: @"";
    [self.faceQualityLabel setHidden:!self.faceQualityLabel.text.length];
}

- (CGRect)layoutCapturePreviewIfNeededWithPixelSize:(CGSize)pixelSize {
    if (pixelSize.width <= 0 || pixelSize.height <= 0) {
        return self.view.bounds;
    }
    CGFloat newWidth = self.view.bounds.size.width;
    CGFloat newHeight = newWidth * (pixelSize.height / pixelSize.width);
    if (newHeight < self.view.bounds.size.height) {
        newHeight = self.view.bounds.size.height;
        newWidth = newHeight / (pixelSize.height / pixelSize.width);
    }
    return CGRectMake(-(newWidth - self.view.btd_width) / 2.0, -(newHeight - self.view.btd_height) / 2.0, newWidth, newHeight);
}

- (void)resetReadTextHighLightProgress {
    [self updateReadTextHighLightProgress:0];
}

- (BOOL)updateReadTextHighLightProgress:(int)length {
    UILabel *contentLabel = [self contentLabel];
    UILabel *fakeContentLabel = [self fakeContentLabel];
    @autoreleasepool {
        NSAttributedString *attributedString = [self attributedContentStringWithHighLigthLength:length];
        [contentLabel setAttributedText:attributedString];

        NSAttributedString *tmpAttributedString = [attributedString attributedSubstringFromRange:NSMakeRange(0, length)];
        fakeContentLabel.attributedText = tmpAttributedString;

        if (contentLabel.btd_height > contentLabel.superview.btd_height && length > 0) {
            int scrollStyle = 0;
            if (scrollStyle == 0) {
                if (([fakeContentLabel sizeThatFits:CGSizeMake(contentLabel.btd_width, CGFLOAT_MAX)].height + contentLabel.btd_top) > ceilf(contentLabel.font.lineHeight + kBDCTVideRecordContentTextLineSpace + 1)) {
                    if (contentLabel.btd_bottom > (contentLabel.font.lineHeight + kBDCTVideRecordContentTextLineSpace) * 2) {
                        [UIView animateWithDuration:0.25 animations:^{
                            [self contentLabel].btd_top -= (contentLabel.font.lineHeight + kBDCTVideRecordContentTextLineSpace);
                        }];
                    }
                }
            } else {
                if (([fakeContentLabel sizeThatFits:CGSizeMake(contentLabel.btd_width, CGFLOAT_MAX)].height + contentLabel.btd_top) > (contentLabel.superview.btd_height - 1)) {
                    [UIView animateWithDuration:0.25 animations:^{
                        [self contentLabel].btd_top -= contentLabel.font.lineHeight + kBDCTVideRecordContentTextLineSpace;
                    }];
                }
            }
        } else {
            [UIView animateWithDuration:0.25 animations:^{
                [self contentLabel].btd_top = 0;
            }];
        }
    }
    if (length >= contentLabel.text.length) {
        return YES;
    }
    return NO;
}

@end
