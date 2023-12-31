//
//  BytedCertIndicatorView.m
//  AFgzipRequestSerializer
//
//  Created by xunianqiang on 2020/3/15.
//

#import "BDCTIndicatorView.h"
#import "BDCTWaitingView.h"
#import "UIImage+BDCTAdditions.h"
#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/UIView+BTDAdditions.h>

static NSInteger const indicatorTextLabelMaxLineNumber = 2;
static CGFloat const topPadding = 20.f;
static CGFloat const bottomPadding = 20.f;
static CGFloat const itemSpacing = 10.f;
static CGFloat const horiSpacing = 20.f;

static CGFloat const indicatorMaxWidth = 160.f;

static CGFloat const defaultDisplayDuration = 1.f;
static CGFloat const showAnimationDuration = 0.5f;
static CGFloat const hideAnimationDuration = 0.5f;
static CGFloat const defaultDismissDelay = 0.5f;

static CGFloat const indicatorTextFontSize = 15.f;


@interface BDCTIndicatorContentView : UIView
@end


@implementation BDCTIndicatorContentView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = 5.f;
    }
    return self;
}

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (CGSize)sizeThatFits:(CGSize)size {
    __block CGFloat contentWidth = 0;
    __block CGFloat contentHeight = topPadding + bottomPadding;
    __block NSInteger unHiddenSubViewCount = 0;
    for (UIView *subView in self.subviews) {
        if (BytedCertShown(subView) && ![subView isKindOfClass:[UIButton class]]) {
            contentWidth = MAX(subView.frame.size.width, contentWidth);
            contentHeight += subView.frame.size.height;
            unHiddenSubViewCount++;
        }
    }
    contentWidth += horiSpacing * 2;
    if (unHiddenSubViewCount > 1) {
        contentHeight += (unHiddenSubViewCount - 1) * itemSpacing;
    }
    return CGSizeMake(contentWidth, contentHeight);
}

@end


@interface BDCTIndicatorView ()

@property (nonatomic, assign) BytedCertIndicatorViewStyle indicatorStyle;

@property (nonatomic, strong) UILabel *indicatorTextLabel;
@property (nonatomic, strong) UIImageView *indicatorImageView;
@property (nonatomic, strong) BDCTWaitingView *indicatorWaitingView;
@property (nonatomic, strong) BDCTIndicatorContentView *contentView;

@property (nonatomic, weak) UIView *parentView;

@property (nonatomic, copy) NSString *indicatorText;
@property (nonatomic, copy) UIImage *indicatorImage;
@property (nonatomic, assign) NSInteger supportMaxLine;
@property (nonatomic, assign) CGFloat expectedWidth;

@property (nonatomic, copy) DismissHandler dismissHandler;
@property (nonatomic, assign) BOOL isUserDismiss;

@end


@implementation BDCTIndicatorView

#pragma mark - Initialization

- (instancetype)initWithIndicatorStyle:(BytedCertIndicatorViewStyle)style
                         indicatorText:(NSString *)indicatorText
                        indicatorImage:(UIImage *)indicatorImage
                        dismissHandler:(DismissHandler)handler {
    return [self initWithIndicatorStyle:style
                          indicatorText:indicatorText
                         indicatorImage:indicatorImage
                                maxLine:indicatorTextLabelMaxLineNumber
                         dismissHandler:handler];
}

- (nonnull instancetype)initWithIndicatorStyle:(BytedCertIndicatorViewStyle)style
                                 indicatorText:(NSString *)indicatorText
                                indicatorImage:(UIImage *)indicatorImage
                                       maxLine:(NSInteger)maxLine
                                dismissHandler:(DismissHandler)handler {
    return [self initWithIndicatorStyle:style
                          indicatorText:indicatorText
                         indicatorImage:indicatorImage
                                maxLine:maxLine
                          expectedWidth:-1
                         dismissHandler:handler];
}

- (instancetype)initWithIndicatorStyle:(BytedCertIndicatorViewStyle)style
                         indicatorText:(NSString *)indicatorText
                        indicatorImage:(UIImage *)indicatorImage
                               maxLine:(NSInteger)maxLine
                         expectedWidth:(CGFloat)expectedWidth
                        dismissHandler:(DismissHandler)handler {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _indicatorStyle = style;
        _indicatorText = indicatorText;
        _indicatorImage = indicatorImage;
        _showDismissButton = YES;
        _autoDismiss = YES;
        _dismissHandler = handler;
        _supportMaxLine = maxLine;
        _dismissDelay = defaultDismissDelay;
        _expectedWidth = expectedWidth;
        [self initSubViews];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithIndicatorStyle:BytedCertIndicatorViewStyleImage indicatorText:nil indicatorImage:nil dismissHandler:nil];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithIndicatorStyle:BytedCertIndicatorViewStyleImage indicatorText:nil indicatorImage:nil dismissHandler:nil];
}

- (void)initSubViews {
    _contentView = [[BDCTIndicatorContentView alloc] init];
    [self addSubview:_contentView];

    _indicatorImageView = [UIImageView new];
    _indicatorImageView.contentMode = UIViewContentModeScaleAspectFill;
    if (_indicatorImage) {
        [self _layoutIndicatorImageViewWithImage:_indicatorImage];
    }
    [_contentView addSubview:_indicatorImageView];

    _indicatorTextLabel = [UILabel new];
    _indicatorTextLabel.backgroundColor = [UIColor clearColor];
    _indicatorTextLabel.textColor = [UIColor whiteColor];
    _indicatorTextLabel.font = [UIFont systemFontOfSize:indicatorTextFontSize];
    _indicatorTextLabel.textAlignment = NSTextAlignmentCenter;
    _indicatorTextLabel.numberOfLines = _supportMaxLine;
    _indicatorTextLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    if (!BTD_isEmptyString(_indicatorText)) {
        [self _layoutIndicatorLabelWithText:_indicatorText];
    }
    [_contentView addSubview:_indicatorTextLabel];

    _indicatorWaitingView = [BDCTWaitingView new];
    _indicatorWaitingView.imageView.image = [UIImage bdct_loadingImage];
    if ([self _needShowWaitingView]) {
        [_contentView addSubview:_indicatorWaitingView];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeStatusBarOrientationChanged:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)p_needTransform {
    UIInterfaceOrientation ori = [UIApplication sharedApplication].statusBarOrientation;
    if ((_parentView.frame.size.width > _parentView.frame.size.height && UIInterfaceOrientationIsPortrait(ori)) || (_parentView.frame.size.width < _parentView.frame.size.height && UIInterfaceOrientationIsLandscape(ori))) {
        return YES;
    } else {
        return NO;
    }
}

- (void)observeStatusBarOrientationChanged:(NSNotification *)aNotification {
    [self setNeedsLayout];
    NSNumber *orientationNumber = aNotification.userInfo[UIApplicationStatusBarOrientationUserInfoKey];
    UIInterfaceOrientation orientation = orientationNumber.integerValue;
    [self rotateContentForInterfaceOrientation:orientation];
}

#pragma mark - Layout

- (void)layoutSubviews {
    _indicatorImageView.hidden = !_indicatorImage || [self _needShowWaitingView];
    _indicatorTextLabel.hidden = BTD_isEmptyString(_indicatorText);
    _indicatorWaitingView.hidden = ![self _needShowWaitingView];
    [_contentView sizeToFit];
    _contentView.center = CGPointMake(_parentView.btd_width / 2, _parentView.btd_height / 2);
    if (BytedCertShown(_indicatorImageView)) {
        _indicatorImageView.btd_centerX = _contentView.bounds.size.width / 2;
        _indicatorImageView.btd_top = topPadding;
        if (BytedCertShown(_indicatorTextLabel)) {
            _indicatorTextLabel.btd_centerX = _contentView.bounds.size.width / 2;
            _indicatorTextLabel.btd_top = _indicatorImageView.btd_bottom + itemSpacing;
        }
    } else {
        CGFloat contentBaseLine = topPadding;
        if (BytedCertShown(_indicatorWaitingView)) {
            _indicatorWaitingView.btd_centerX = _contentView.bounds.size.width / 2;
            _indicatorWaitingView.btd_top = topPadding;
            contentBaseLine = _indicatorWaitingView.btd_bottom + itemSpacing;
        }
        if (BytedCertShown(_indicatorTextLabel)) {
            _indicatorTextLabel.btd_centerX = _contentView.bounds.size.width / 2;
            _indicatorTextLabel.btd_top = contentBaseLine;
            contentBaseLine = _indicatorTextLabel.btd_bottom + itemSpacing;
        }
    }
}

- (void)rotateContentForInterfaceOrientation:(UIInterfaceOrientation)orientation {
    switch (orientation) {
        case UIInterfaceOrientationUnknown:
            break;
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
            _contentView.transform = CGAffineTransformIdentity;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            _contentView.transform = CGAffineTransformMakeRotation(-M_PI_2);
            break;
        case UIInterfaceOrientationLandscapeRight:
            _contentView.transform = CGAffineTransformMakeRotation(M_PI_2);
            break;
    }
}

#pragma mark - Show

- (void)showFromParentView:(UIView *)parentView {
    [self showFromParentView:parentView offset:UIOffsetMake(0, 0)];
}

- (void)showFromParentView:(UIView *)parentView offset:(UIOffset)offset {
    if (!parentView) {
        parentView = [self.class _defaultParentView];
    }

    _parentView = parentView;
    [self _dismissAllCurrentIndicators];
    [_parentView addSubview:self];
    self.btd_width = parentView.btd_width;
    self.btd_height = parentView.btd_height;
    self.center = CGPointMake(parentView.btd_centerX + offset.horizontal, parentView.btd_centerY + offset.vertical);
    self.userInteractionEnabled = _showDismissButton;

    self.alpha = 0.f;
    if ([self p_needTransform]) {
        [self rotateContentForInterfaceOrientation:UIApplication.sharedApplication.statusBarOrientation];
    }
    _indicatorImageView.alpha = 0.f;
    _indicatorTextLabel.alpha = 0.f;
    _indicatorImageView.transform = CGAffineTransformMakeScale(0.f, 0.f);
    if ([self _needShowWaitingView]) {
        [_indicatorWaitingView startAnimating];
    }
    [UIView animateWithDuration:showAnimationDuration delay:0.f usingSpringWithDamping:0.8f initialSpringVelocity:0.f options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.alpha = 1.f;
    } completion:^(BOOL finished) {
        if (self.autoDismiss) {
            [self performSelector:@selector(dismissFromParentView) withObject:nil afterDelay:self.duration > 0 ? self.duration : defaultDisplayDuration];
        }
    }];
    [UIView animateWithDuration:showAnimationDuration - 0.1 delay:0.1f usingSpringWithDamping:0.6 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.indicatorImageView.transform = CGAffineTransformMakeScale(1.f, 1.f);
        self.indicatorImageView.alpha = 1.f;
        self.indicatorTextLabel.alpha = 1.f;
    } completion:^(BOOL finished){
    }];
}

+ (void)showWithIndicatorStyle:(BytedCertIndicatorViewStyle)style
                 indicatorText:(NSString *)indicatorText
                indicatorImage:(UIImage *)indicatorImage
                   autoDismiss:(BOOL)autoDismiss
                dismissHandler:(DismissHandler)handler {
    return [self showWithIndicatorStyle:style
                          indicatorText:indicatorText
                         indicatorImage:indicatorImage
                                maxLine:indicatorTextLabelMaxLineNumber
                          expectedWidth:-1
                            autoDismiss:autoDismiss
                         dismissHandler:handler];
}

+ (void)showWithIndicatorStyle:(BytedCertIndicatorViewStyle)style
                 indicatorText:(nullable NSString *)indicatorText
                indicatorImage:(nullable UIImage *)indicatorImage
                       maxLine:(NSInteger)maxLine
                   autoDismiss:(BOOL)autoDismiss
                dismissHandler:(nullable DismissHandler)handler {
    BDCTIndicatorView *indicatorView = [[BDCTIndicatorView alloc] initWithIndicatorStyle:style indicatorText:indicatorText indicatorImage:indicatorImage maxLine:maxLine expectedWidth:-1 dismissHandler:handler];
    indicatorView.autoDismiss = autoDismiss;
    [indicatorView showFromParentView:[self.class _defaultParentView]];
}

+ (void)showWithIndicatorStyle:(BytedCertIndicatorViewStyle)style
                 indicatorText:(nullable NSString *)indicatorText
                indicatorImage:(nullable UIImage *)indicatorImage
                       maxLine:(NSInteger)maxLine
                 expectedWidth:(CGFloat)expectedWidth
                   autoDismiss:(BOOL)autoDismiss
                dismissHandler:(nullable DismissHandler)handler {
    BDCTIndicatorView *indicatorView = [[BDCTIndicatorView alloc] initWithIndicatorStyle:style indicatorText:indicatorText indicatorImage:indicatorImage maxLine:maxLine expectedWidth:expectedWidth dismissHandler:handler];
    indicatorView.autoDismiss = autoDismiss;
    [indicatorView showFromParentView:[self.class _defaultParentView]];
}

#pragma mark - Dismiss

- (void)dismissByUser {
    _isUserDismiss = YES;
    [self dismissFromParentView];
}

- (void)dismissFromParentView {
    [self _dismissFromParentViewAnimated:YES];
}

- (void)_dismissFromParentViewAnimated:(BOOL)animated {
    void (^completion)(BOOL finished) = ^(BOOL finished) {
        self.alpha = 0.f;
        self.indicatorText = nil;
        self.indicatorImage = nil;
        if ([self _needShowWaitingView]) {
            [self.indicatorWaitingView stopAnimating];
        }
        [self removeFromSuperview];
        self.parentView = nil;
        if (self.dismissHandler) {
            self.dismissHandler(self.isUserDismiss);
            self.isUserDismiss = NO;
        }
    };
    if (animated) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.dismissDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:hideAnimationDuration
                animations:^{
                    self.alpha = 0.f;
                }
                completion:^(BOOL finished) {
                    completion(finished);
                }];
        });
    } else {
        completion(YES);
    }
}

- (void)_dismissAllCurrentIndicators {
    [self _dismissAllCurrentIndicatorsOnParentView:_parentView animated:NO];
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        [self _dismissAllCurrentIndicatorsOnParentView:window animated:NO];
    }
}

- (void)_dismissAllCurrentIndicatorsOnParentView:(UIView *)parentView animated:(BOOL)animated {
    for (UIView *subView in parentView.subviews) {
        if ([subView isKindOfClass:[BDCTIndicatorView class]]) {
            [((BDCTIndicatorView *)subView) _dismissFromParentViewAnimated:animated];
        }
    }
}

+ (void)dismissIndicators {
    if (NSThread.currentThread.isMainThread) {
        [self _dismissIndicators];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _dismissIndicators];
        });
    }
}

+ (void)_dismissIndicators {
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        for (UIView *subView in window.subviews) {
            if ([subView isKindOfClass:[BDCTIndicatorView class]]) {
                [((BDCTIndicatorView *)subView) _dismissFromParentViewAnimated:NO];
            }
        }
    }
}

#pragma mark - Setter

- (void)setShowDismissButton:(BOOL)showDismissButton {
    _showDismissButton = showDismissButton;
    self.userInteractionEnabled = _showDismissButton;
    [self setNeedsLayout];
}

- (void)setDismissDelay:(NSTimeInterval)dissmissDelay {
    dissmissDelay = MAX(0, dissmissDelay);

    _dismissDelay = dissmissDelay;
}

#pragma mark - Update
- (void)updateIndicatorWithText:(NSString *)updateIndicatorText
        shouldRemoveWaitingView:(BOOL)shouldRemoveWaitingView {
    if (shouldRemoveWaitingView) {
        /**
         *  只是改变style，让waitingView隐藏
         */
        _indicatorStyle = BytedCertIndicatorViewStyleImage;
    }
    [self _layoutIndicatorLabelWithText:updateIndicatorText];
    [self setNeedsLayout];
}

- (void)updateIndicatorWithImage:(UIImage *)updateIndicatorImage {
    _indicatorStyle = BytedCertIndicatorViewStyleImage;
    [self _layoutIndicatorImageViewWithImage:updateIndicatorImage];
    [self setNeedsLayout];
}

#pragma mark - Private

+ (UIView *)_defaultParentView {
    if ([[UIApplication sharedApplication] keyWindow]) {
        return [[UIApplication sharedApplication] keyWindow];
    }

    if ([[[UIApplication sharedApplication] delegate] respondsToSelector:@selector(window)]) {
        return [[[UIApplication sharedApplication] delegate] window];
    }
    return nil;
}

- (BOOL)_needShowWaitingView {
    return _indicatorStyle == BytedCertIndicatorViewStyleWaitingView;
}

- (void)_layoutIndicatorLabelWithText:(NSString *)text {
    _indicatorText = text;
    _indicatorTextLabel.text = _indicatorText;
    //singleLine size
    CGSize labelSize = [_indicatorText sizeWithAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:indicatorTextFontSize]}];
    if (labelSize.width > self.indicatorMaxWidth) {
        labelSize.width = self.indicatorMaxWidth;
        labelSize.height = [self.class heightOfText:text fontSize:indicatorTextFontSize forWidth:self.indicatorMaxWidth forLineHeight:[UIFont systemFontOfSize:indicatorTextFontSize].lineHeight constraintToMaxNumberOfLines:_supportMaxLine firstLineIndent:0 textAlignment:NSTextAlignmentCenter];
    }
    _indicatorTextLabel.btd_width = labelSize.width;
    _indicatorTextLabel.btd_height = labelSize.height;
}

+ (CGFloat)heightOfText:(NSString *)text fontSize:(CGFloat)fontSize forWidth:(CGFloat)width forLineHeight:(CGFloat)lineHeight constraintToMaxNumberOfLines:(NSInteger)numberOfLines firstLineIndent:(CGFloat)indent textAlignment:(NSTextAlignment)alignment {
    return [[self class] heightOfText:text fontSize:fontSize forWidth:width forLineHeight:lineHeight constraintToMaxNumberOfLines:numberOfLines firstLineIndent:indent textAlignment:alignment lineBreakMode:NSLineBreakByCharWrapping];
}

/**
 *  @param alignment 断行方式
 */
+ (CGFloat)heightOfText:(NSString *)text fontSize:(CGFloat)fontSize forWidth:(CGFloat)width forLineHeight:(CGFloat)lineHeight constraintToMaxNumberOfLines:(NSInteger)numberOfLines firstLineIndent:(CGFloat)indent textAlignment:(NSTextAlignment)alignment lineBreakMode:(NSLineBreakMode)lineBreakMode {
    CGSize size = [[self class] sizeOfText:text fontSize:fontSize forWidth:width forLineHeight:lineHeight constraintToMaxNumberOfLines:numberOfLines firstLineIndent:indent textAlignment:alignment lineBreakMode:lineBreakMode];
    size.height = ceil(size.height);
    return size.height;
}

+ (CGSize)sizeOfText:(NSString *)text fontSize:(CGFloat)fontSize forWidth:(CGFloat)width forLineHeight:(CGFloat)lineHeight constraintToMaxNumberOfLines:(NSInteger)numberOfLines firstLineIndent:(CGFloat)indent textAlignment:(NSTextAlignment)alignment lineBreakMode:(NSLineBreakMode)lineBreakMode {
    CGSize size = CGSizeZero;
    if ([text length] > 0) {
        UIFont *font = [UIFont systemFontOfSize:fontSize];
        CGFloat constraintHeight = numberOfLines ? numberOfLines * (lineHeight + 1) : 9999.f;
        CGFloat lineHeightMultiple = lineHeight / font.lineHeight;

        //        if ([self _shouldHandleJailBrokenCase]) {
        //            NSAttributedString *attrString = [self attributedStringWithString:text fontSize:fontSize lineHeight:lineHeight lineBreakMode:NSLineBreakByCharWrapping isBoldFontStyle:NO firstLineIndent:indent textAlignment:alignment];
        //            size = [attrString boundingRectWithSize:CGSizeMake(width, constraintHeight) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
        //        }
        //        else {
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        style.lineBreakMode = lineBreakMode;
        style.alignment = alignment;
        style.lineHeightMultiple = lineHeightMultiple;
        style.minimumLineHeight = font.lineHeight * lineHeightMultiple;
        style.maximumLineHeight = font.lineHeight * lineHeightMultiple;
        style.firstLineHeadIndent = indent;
        size = [text boundingRectWithSize:CGSizeMake(width, constraintHeight)
                                  options:NSStringDrawingUsesLineFragmentOrigin
                               attributes:@{
                                   NSFontAttributeName : font,
                                   NSParagraphStyleAttributeName : style,
                               }
                                  context:nil]
                   .size;
        //        }
    }
    return size;
}

+ (NSDictionary *)_attributesWithFontSize:(CGFloat)fontSize lineHeight:(CGFloat)lineHeight lineBreakMode:(NSLineBreakMode)lineBreakMode isBoldFontStyle:(BOOL)isBold firstLineIndent:(CGFloat)indent textAlignment:(NSTextAlignment)alignment {
    UIFont *font = isBold ? [UIFont boldSystemFontOfSize:fontSize] : [UIFont systemFontOfSize:fontSize];
    CGFloat lineHeightMultiple = lineHeight / font.lineHeight;

    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = lineBreakMode;
    style.alignment = alignment;
    style.lineHeightMultiple = lineHeightMultiple;
    style.minimumLineHeight = font.lineHeight * lineHeightMultiple;
    style.maximumLineHeight = font.lineHeight * lineHeightMultiple;
    style.firstLineHeadIndent = indent;
    NSDictionary *attributes = @{NSFontAttributeName : font, NSParagraphStyleAttributeName : style};
    return attributes;
}

- (void)_layoutIndicatorImageViewWithImage:(UIImage *)image {
    _indicatorImage = image;
    [_indicatorImageView setImage:image];
    _indicatorImageView.btd_width = _indicatorImageView.btd_height = 6;
}

+ (void)showIndicatorForFollowMessage:(NSString *)msg {
    [BDCTIndicatorView showWithIndicatorStyle:BytedCertIndicatorViewStyleImage indicatorText:msg indicatorImage:[UIImage imageNamed:@"close_popup_textpage"] autoDismiss:YES dismissHandler:nil];
}

- (CGFloat)indicatorMaxWidth {
    if (self.expectedWidth <= 0 || self.expectedWidth >= UIScreen.mainScreen.bounds.size.width) {
        return indicatorMaxWidth;
    } else {
        return self.expectedWidth;
    }
}

@end
