//
//  BDTuringIndicatorView.m
//  AFgzipRequestSerializer
//
//  Created by xunianqiang on 2020/3/15.
//

#import "BDTuringIndicatorView.h"
#import "BDTuringWaitingView.h"
#import "BDTuringMacro.h"
#import "BDTuringViewAdditions.h"
#import "BDTuringUtility.h"

static NSInteger const indicatorTextLabelMaxLineNumber = 2;
static CGFloat const topPadding = 20.f;
static CGFloat const bottomPadding = 20.f;
static CGFloat const itemSpacing = 10.f;
static CGFloat const horiSpacing = 20.f;
static CGFloat const dismissButtonPadding = 10.f;

static CGFloat const indicatorMaxWidth = 160.f;

static CGFloat const defaultDisplayDuration = 1.f;
static CGFloat const showAnimationDuration = 0.5f;
static CGFloat const hideAnimationDuration = 0.5f;
static CGFloat const defaultDismissDelay = 0.5f;

static CGFloat const indicatorTextFontSize = 17.f;

@interface BDTuringIndicatorContentView : UIView
@end

@implementation BDTuringIndicatorContentView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = 5.f;
    }
    return self;
}

- (instancetype)init
{
    return [self initWithFrame:CGRectZero];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    __block CGFloat contentWidth = 0;
    __block CGFloat contentHeight = topPadding + bottomPadding;
    __block NSInteger unHiddenSubViewCount = 0;
    for (UIView * subView in self.subviews) {
        if (BDTuringShown(subView) && ![subView isKindOfClass:[UIButton class]]) {
            contentWidth = MAX(subView.frame.size.width, contentWidth);
            contentHeight += subView.frame.size.height;
            unHiddenSubViewCount++;
        }
    }
    contentWidth += horiSpacing*2;
    if (unHiddenSubViewCount > 1) {
        contentHeight += (unHiddenSubViewCount - 1) * itemSpacing;
    }
    return CGSizeMake(contentWidth, contentHeight);
}

@end

@interface BDTuringIndicatorView ()

@property(nonatomic, assign) BDTuringIndicatorViewStyle indicatorStyle;

@property(nonatomic, strong) UILabel *indicatorTextLabel;
@property(nonatomic, strong) UIImageView *indicatorImageView;
@property(nonatomic, strong) BDTuringWaitingView *indicatorWaitingView;
@property(nonatomic, strong) UIButton *dismissButton;
@property(nonatomic, strong) BDTuringIndicatorContentView *contentView;
@property(nonatomic, weak) UIView *parentView;

@property(nonatomic, copy) NSString *indicatorText;
@property(nonatomic, copy) UIImage *indicatorImage;

@property(nonatomic, copy) DismissHandler dismissHandler;
@property(nonatomic, assign) BOOL isUserDismiss;
@property(nonatomic, assign) NSInteger supportMaxLine;
@property (nonatomic) CGFloat expectedWidth;


@end

@implementation BDTuringIndicatorView

#pragma mark - Initialization

- (instancetype)initWithIndicatorStyle:(BDTuringIndicatorViewStyle)style
                         indicatorText:(NSString *)indicatorText
                        indicatorImage:(UIImage *)indicatorImage
                        dismissHandler:(DismissHandler)handler
{
    return [self initWithIndicatorStyle:style
                          indicatorText:indicatorText
                         indicatorImage:indicatorImage
                                maxLine:indicatorTextLabelMaxLineNumber
                         dismissHandler:handler];
}

- (nonnull instancetype)initWithIndicatorStyle:(BDTuringIndicatorViewStyle)style
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

- (instancetype)initWithIndicatorStyle:(BDTuringIndicatorViewStyle)style
                         indicatorText:(NSString *)indicatorText
                        indicatorImage:(UIImage *)indicatorImage
                               maxLine:(NSInteger)maxLine
                         expectedWidth:(CGFloat)expectedWidth
                        dismissHandler:(DismissHandler)handler
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _indicatorStyle = style;
        _indicatorText = indicatorText;
        _indicatorImage = indicatorImage;
        _showDismissButton = NO;
        _autoDismiss = YES;
        _dismissHandler = handler;
        _supportMaxLine = maxLine;
        _dismissDelay = defaultDismissDelay;
        _expectedWidth = expectedWidth;
        [self initSubViews];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithIndicatorStyle:BDTuringIndicatorViewStyleImage indicatorText:nil indicatorImage:nil dismissHandler:nil];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    return [self initWithIndicatorStyle:BDTuringIndicatorViewStyleImage indicatorText:nil indicatorImage:nil dismissHandler:nil];
}

- (void)initSubViews
{
    _contentView = [[BDTuringIndicatorContentView alloc] init];
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
    if (BDTuring_isValidString(_indicatorText)) {
        [self _layoutIndicatorLabelWithText:_indicatorText];
    }
    [_contentView addSubview:_indicatorTextLabel];
    
    _indicatorWaitingView = [BDTuringWaitingView new];
    _indicatorWaitingView.imageView.image = [self getLoadingUIImage];
    if ([self _needShowWaitingView]) {
        [_contentView addSubview:_indicatorWaitingView];
    }
    
    _dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _dismissButton.size = CGSizeMake(8, 8);
//    _dismissButton.hitTestEdgeInsets = UIEdgeInsetsMake(-5, -5, -5, -5);
//    _dismissButton.imageName = @"close_move_details";
    /**
     *  默认隐藏
     */
    _dismissButton.hidden = YES;
    [_dismissButton addTarget:self
                       action:@selector(dismissByUser)
             forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:self.dismissButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeStatusBarOrientationChanged:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
}

- (void)dealloc
{
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

- (void)observeStatusBarOrientationChanged:(NSNotification *)aNotification
{
    [self setNeedsLayout];
    
    NSNumber *orientationNumber = aNotification.userInfo[UIApplicationStatusBarOrientationUserInfoKey];
    UIInterfaceOrientation orientation = orientationNumber.integerValue;
    [self rotateContentForInterfaceOrientation:orientation];
}

#pragma mark - Layout

- (void)layoutSubviews
{
    _indicatorImageView.hidden = !_indicatorImage || [self _needShowWaitingView];
    _indicatorTextLabel.hidden = !BDTuring_isValidString(_indicatorText);
    _indicatorWaitingView.hidden = ![self _needShowWaitingView];
    _dismissButton.hidden = !_showDismissButton;
    [_contentView sizeToFit];
    _contentView.center = CGPointMake(_parentView.width/2, _parentView.height/2);
    if (BDTuringShown(_indicatorImageView)) {
        _indicatorImageView.centerX = _contentView.bounds.size.width/2;
        _indicatorImageView.top = topPadding;
        if (BDTuringShown(_indicatorTextLabel)) {
            _indicatorTextLabel.centerX = _contentView.bounds.size.width/2;
            _indicatorTextLabel.top = _indicatorImageView.bottom + itemSpacing;
        }
    }
    else {
        CGFloat contentBaseLine = topPadding;
        if (BDTuringShown(_indicatorWaitingView)) {
            _indicatorWaitingView.centerX = _contentView.bounds.size.width/2;
            _indicatorWaitingView.top = topPadding;
            contentBaseLine = _indicatorWaitingView.bottom + itemSpacing;
        }
        if (BDTuringShown(_indicatorTextLabel)) {
            _indicatorTextLabel.centerX = _contentView.bounds.size.width/2;
            _indicatorTextLabel.top = contentBaseLine;
            contentBaseLine = _indicatorTextLabel.bottom + itemSpacing;
        }
    }
    
    if (BDTuringShown(_dismissButton)) {
        _dismissButton.origin = CGPointMake(_contentView.width - dismissButtonPadding - _dismissButton.width, dismissButtonPadding);
    }
    
    [self makeRotationTransformOnIOS7];
    [self layoutContentSubViewsOnIOS7];
}

- (void)makeRotationTransformOnIOS7
{
    if ([self.class OSVersionNumber] < 8.f && [self p_needTransform]) {
        switch ([UIApplication sharedApplication].statusBarOrientation) {
            case UIInterfaceOrientationPortrait:
            case UIInterfaceOrientationPortraitUpsideDown:
                _contentView.transform = CGAffineTransformIdentity;
                break;
            case UIInterfaceOrientationLandscapeLeft:
                _contentView.transform = CGAffineTransformMakeRotation(-M_PI/2);
                break;
            case UIInterfaceOrientationLandscapeRight:
                _contentView.transform = CGAffineTransformMakeRotation(M_PI/2);
                break;
            default:
                break;
        }
    }
}

- (void)layoutContentSubViewsOnIOS7
{
    if ([self.class OSVersionNumber] < 8.f && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        _indicatorImageView.centerX = _contentView.height/2;
        _indicatorTextLabel.centerX = _contentView.height/2;
        _indicatorWaitingView.centerX = _contentView.height/2;
    }
}

- (void)rotateContentForInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    switch (orientation) {
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

+ (float)OSVersionNumber {
    static float currentOsVersionNumber = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        currentOsVersionNumber = [[[UIDevice currentDevice] systemVersion] floatValue];
    });
    return currentOsVersionNumber;
}

#pragma mark - Show

- (void)showFromParentView:(UIView *)parentView
{
    [self showFromParentView:parentView offset:UIOffsetMake(0, 0)];
}

- (void)showFromParentView:(UIView *)parentView offset:(UIOffset)offset
{
    if (!parentView) {
        parentView = [self.class _defaultParentView];
    }
    
    _parentView = parentView;
    [self _dismissAllCurrentIndicators];
    [_parentView addSubview:self];
    self.size = CGSizeMake(parentView.width, parentView.height);
    self.center = CGPointMake(parentView.centerX + offset.horizontal, parentView.centerY + offset.vertical);
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
        if (_autoDismiss) {
            [self performSelector:@selector(dismissFromParentView) withObject:nil afterDelay:self.duration > 0? self.duration: defaultDisplayDuration];
        }
    }];
    [UIView animateWithDuration:showAnimationDuration-0.1 delay:0.1f usingSpringWithDamping:0.6 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        _indicatorImageView.transform = CGAffineTransformMakeScale(1.f, 1.f);
        _indicatorImageView.alpha = 1.f;
        _indicatorTextLabel.alpha = 1.f;
    } completion:^(BOOL finished) {
    }];
}

+ (void)showWithIndicatorStyle:(BDTuringIndicatorViewStyle)style
                 indicatorText:(NSString *)indicatorText
                indicatorImage:(UIImage *)indicatorImage
                   autoDismiss:(BOOL)autoDismiss
                dismissHandler:(DismissHandler)handler
{
    return [self showWithIndicatorStyle:style
                          indicatorText:indicatorText
                         indicatorImage:indicatorImage
                                maxLine:indicatorTextLabelMaxLineNumber
                          expectedWidth:-1
                            autoDismiss:autoDismiss
                         dismissHandler:handler];
}

+ (void)showWithIndicatorStyle:(BDTuringIndicatorViewStyle)style
                 indicatorText:(nullable NSString *)indicatorText
                indicatorImage:(nullable UIImage *)indicatorImage
                       maxLine:(NSInteger)maxLine
                   autoDismiss:(BOOL)autoDismiss
                dismissHandler:(nullable DismissHandler)handler
{
    BDTuringIndicatorView *indicatorView = [[BDTuringIndicatorView alloc] initWithIndicatorStyle:style indicatorText:indicatorText indicatorImage:indicatorImage maxLine:maxLine expectedWidth:-1 dismissHandler:handler];
    indicatorView.autoDismiss = autoDismiss;
    [indicatorView showFromParentView:[self.class _defaultParentView]];
}

+ (void)showWithIndicatorStyle:(BDTuringIndicatorViewStyle)style
                 indicatorText:(nullable NSString *)indicatorText
                indicatorImage:(nullable UIImage *)indicatorImage
                       maxLine:(NSInteger)maxLine
                 expectedWidth:(CGFloat)expectedWidth
                   autoDismiss:(BOOL)autoDismiss
                dismissHandler:(nullable DismissHandler)handler {
    BDTuringIndicatorView *indicatorView = [[BDTuringIndicatorView alloc] initWithIndicatorStyle:style indicatorText:indicatorText indicatorImage:indicatorImage maxLine:maxLine expectedWidth:expectedWidth dismissHandler:handler];
    indicatorView.autoDismiss = autoDismiss;
    [indicatorView showFromParentView:[self.class _defaultParentView]];
}

#pragma mark - Dismiss

- (void)dismissByUser
{
    _isUserDismiss = YES;
    [self dismissFromParentView];
}

- (void)dismissFromParentView
{
    [self _dismissFromParentViewAnimated:YES];
}

- (void)_dismissFromParentViewAnimated:(BOOL)animated
{
    void (^completion)(BOOL finished) = ^(BOOL finished) {
        self.alpha = 0.f;
        self.indicatorText = nil;
        self.indicatorImage = nil;
        if ([self _needShowWaitingView]) {
            [_indicatorWaitingView stopAnimating];
        }
        [self removeFromSuperview];
        _parentView = nil;
        if (_dismissHandler) {
            _dismissHandler(_isUserDismiss);
            self.isUserDismiss = NO;
        }
    };
    if (animated) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.dismissDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:hideAnimationDuration
                             animations:^{
                                 self.alpha = 0.f;
                             }
                             completion:^(BOOL finished){
                                 completion(finished);
                             }];
        });
    }
    else {
        completion(YES);
    }
}

- (void)_dismissAllCurrentIndicators
{
    [self _dismissAllCurrentIndicatorsOnParentView:_parentView animated:NO];
    for (UIWindow * window in [UIApplication sharedApplication].windows) {
        [self _dismissAllCurrentIndicatorsOnParentView:window animated:NO];
    }
}

- (void)_dismissAllCurrentIndicatorsOnParentView:(UIView *)parentView animated:(BOOL)animated
{
    for (UIView * subView in parentView.subviews) {
        if ([subView isKindOfClass:[BDTuringIndicatorView class]]) {
            [((BDTuringIndicatorView *)subView) _dismissFromParentViewAnimated:animated];
        }
    }
}

+ (void)dismissIndicators
{
    for (UIWindow * window in [UIApplication sharedApplication].windows) {
        for (UIView * subView in window.subviews) {
            if ([subView isKindOfClass:[BDTuringIndicatorView class]]) {
                [((BDTuringIndicatorView *)subView) _dismissFromParentViewAnimated:NO];
            }
        }
    }
}

+ (void)showIndicatorForTextMessage:(NSString *)textStr {
    [BDTuringIndicatorView showWithIndicatorStyle:BDTuringIndicatorViewStyleWaitingView indicatorText:textStr indicatorImage:nil autoDismiss:YES dismissHandler:nil];
}


#pragma mark - Setter

- (void)setShowDismissButton:(BOOL)showDismissButton
{
    _showDismissButton = showDismissButton;
    self.userInteractionEnabled = _showDismissButton;
    [self setNeedsLayout];
}

- (void)setDismissDelay:(NSTimeInterval)dissmissDelay
{
    dissmissDelay = MAX(0, dissmissDelay);
    
    _dismissDelay = dissmissDelay;
}

#pragma mark - Update
- (void)updateIndicatorWithText:(NSString *)updateIndicatorText
        shouldRemoveWaitingView:(BOOL)shouldRemoveWaitingView
{
    if (shouldRemoveWaitingView) {
        /**
         *  只是改变style，让waitingView隐藏
         */
        _indicatorStyle = BDTuringIndicatorViewStyleImage;
    }
    [self _layoutIndicatorLabelWithText:updateIndicatorText];
    [self setNeedsLayout];
}

- (void)updateIndicatorWithImage:(UIImage *)updateIndicatorImage
{
    _indicatorStyle = BDTuringIndicatorViewStyleImage;
    [self _layoutIndicatorImageViewWithImage:updateIndicatorImage];
    [self setNeedsLayout];
}

#pragma mark - Private

+ (UIView *)_defaultParentView
{
    if ([[UIApplication sharedApplication] keyWindow]) {
        return [[UIApplication sharedApplication] keyWindow];
    }
    
    if ([[[UIApplication sharedApplication] delegate] respondsToSelector:@selector(window)]) {
        return [[[UIApplication sharedApplication] delegate] window];
    }
    return nil;
}

- (BOOL)_needShowWaitingView
{
    return _indicatorStyle == BDTuringIndicatorViewStyleWaitingView;
}

- (void)_layoutIndicatorLabelWithText:(NSString *)text
{
    _indicatorText = text;
    _indicatorTextLabel.text = _indicatorText;
    //singleLine size
    CGSize labelSize = [_indicatorText sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:indicatorTextFontSize]}];
    if (labelSize.width > self.indicatorMaxWidth) {
        labelSize.width = self.indicatorMaxWidth;
        labelSize.height = [self.class heightOfText:text fontSize:indicatorTextFontSize forWidth:self.indicatorMaxWidth forLineHeight:[UIFont systemFontOfSize:indicatorTextFontSize].lineHeight constraintToMaxNumberOfLines:_supportMaxLine firstLineIndent:0 textAlignment:NSTextAlignmentCenter];
    }
    _indicatorTextLabel.size = labelSize;
}

+ (CGFloat)heightOfText:(NSString *)text fontSize:(CGFloat)fontSize forWidth:(CGFloat)width forLineHeight:(CGFloat)lineHeight constraintToMaxNumberOfLines:(NSInteger)numberOfLines firstLineIndent:(CGFloat)indent textAlignment:(NSTextAlignment)alignment
{
    return [[self class] heightOfText:text fontSize:fontSize forWidth:width forLineHeight:lineHeight constraintToMaxNumberOfLines:numberOfLines firstLineIndent:indent textAlignment:alignment lineBreakMode:NSLineBreakByCharWrapping];
}

/**
 *  @param alignment 断行方式
 */
+ (CGFloat)heightOfText:(NSString *)text fontSize:(CGFloat)fontSize forWidth:(CGFloat)width forLineHeight:(CGFloat)lineHeight constraintToMaxNumberOfLines:(NSInteger)numberOfLines firstLineIndent:(CGFloat)indent textAlignment:(NSTextAlignment)alignment lineBreakMode:(NSLineBreakMode)lineBreakMode
{
    CGSize size = [[self class] sizeOfText:text fontSize:fontSize forWidth:width forLineHeight:lineHeight constraintToMaxNumberOfLines:numberOfLines firstLineIndent:indent textAlignment:alignment lineBreakMode:lineBreakMode];
    size.height = ceil(size.height);
    return size.height;
}

+ (CGSize)sizeOfText:(NSString *)text fontSize:(CGFloat)fontSize forWidth:(CGFloat)width forLineHeight:(CGFloat)lineHeight constraintToMaxNumberOfLines:(NSInteger)numberOfLines firstLineIndent:(CGFloat)indent textAlignment:(NSTextAlignment)alignment lineBreakMode:(NSLineBreakMode)lineBreakMode
{
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
                                   attributes:@{NSFontAttributeName:font,
                                                NSParagraphStyleAttributeName:style,
                                                }
                                      context:nil].size;
//        }
        
    }
    return size;
}

+ (NSDictionary *)_attributesWithFontSize:(CGFloat)fontSize lineHeight:(CGFloat)lineHeight lineBreakMode:(NSLineBreakMode)lineBreakMode isBoldFontStyle:(BOOL)isBold firstLineIndent:(CGFloat)indent textAlignment:(NSTextAlignment)alignment
{
    UIFont *font = isBold ? [UIFont boldSystemFontOfSize:fontSize] : [UIFont systemFontOfSize:fontSize];
    CGFloat lineHeightMultiple = lineHeight / font.lineHeight;
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = lineBreakMode;
    style.alignment = alignment;
    style.lineHeightMultiple = lineHeightMultiple;
    style.minimumLineHeight = font.lineHeight * lineHeightMultiple;
    style.maximumLineHeight = font.lineHeight * lineHeightMultiple;
    style.firstLineHeadIndent = indent;
    NSDictionary * attributes = @{NSFontAttributeName:font, NSParagraphStyleAttributeName:style};
    return attributes;
}

- (void)_layoutIndicatorImageViewWithImage:(UIImage *)image
{
    _indicatorImage = image;
    [_indicatorImageView setImage:image];
    _indicatorImageView.size = image.size;
}


- (CGFloat)indicatorMaxWidth {
    if (self.expectedWidth <= 0 || self.expectedWidth >= UIScreen.mainScreen.bounds.size.width) {
        return indicatorMaxWidth;
    } else {
        return self.expectedWidth;
    }
}

- (NSBundle*) getBundle {
    NSBundle *bundle = [NSBundle bundleWithPath:
                        [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"BDTuringResource.bundle"]];
    return bundle;
}

- (UIImage*) getLoadingUIImage {
    NSBundle* bundle = [self getBundle];
    return [UIImage imageNamed:@"loading" inBundle:bundle compatibleWithTraitCollection:nil];
}


@end
