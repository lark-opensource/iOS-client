//
//  ACCGrootStickerView.m
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/5/14.
//

#import "ACCGrootStickerView.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKitSticker/ACCStickerUtils.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/NSString+CameraClientResource.h>
#import <CreativeKit/ACCFontProtocol.h>
#import "ACCInteractionStickerFontHelper.h"
#import <CreativeKit/UIImage+CameraClientResource.h>
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/ACCWebImageProtocol.h>
#import "ACCSocialStickerView.h"
#import "ACCRecognitionGrootConfig.h"
#import "ACCRecognitionGrootStickerViewFactory.h"

@interface ACCGrootStickerViewViewModel : NSObject

// text view
@property (nonatomic, strong, readonly) UIColor  *textColor;
@property (nonatomic, strong, readonly) UIFont   *textFont;
@property (nonatomic, assign, readonly) UIEdgeInsets textViewPadding;
@property (nonatomic, strong, readonly) NSArray  *textGradientColors;
@property (nonatomic, assign, readonly) NSInteger gradientdiRect;
// icon
@property (nonatomic, strong, readonly) UIColor  *tintColor;
@property (nonatomic, strong, readonly) UIFont   *iconFont;
@property (nonatomic, copy,   readonly) NSString *iconFontGlyph;
@property (nonatomic, assign, readonly) CGFloat  iconViewLeftInset;
@property (nonatomic, strong, readonly) UIImage  *hashtagIconFontImage;
@property (nonatomic, copy,   readonly) NSString *iconUrl;
// content
@property (nonatomic, assign, readonly) CGFloat contentHorizontalMinMargin;
@property (nonatomic, assign, readonly) CGFloat contentHeight;
@property (nonatomic, strong, readonly) UIColor  *backgroundColor;
@property (nonatomic, assign, readonly) CGFloat cornerRadius;
@property (nonatomic, assign, readonly) CGFloat hashtagContentHeight;
// border
@property (nonatomic, assign, readonly) CGFloat borderHeight;
// view
@property (nonatomic, assign, readonly) CGFloat viewHeight;
@property (nonatomic, assign, readonly) CGFloat textMaxWidth;
@property (nonatomic, assign, readonly) CGFloat hashtagViewHeight;

// groot
@property (nonatomic, strong, readonly) UIColor *grootTintColor;
@property (nonatomic, strong, readonly) UIFont *grootTextFont;
@property (nonatomic, assign, readonly) UIEdgeInsets grootTextViewPadding;
@property (nonatomic, assign, readonly) CGFloat  grootIconViewLeftInset;
@property (nonatomic, assign, readonly) CGFloat grootTextMaxWidth;

@end

@implementation ACCGrootStickerViewViewModel

- (instancetype)initWitheffectModelInfo:(NSString *)effectModelExtraInfo {
    if (self = [super init]) {
        
        BOOL isNewStyle = ACCConfigBool(kConfigBool_sticker_support_poi_mention_hashtag_UI_uniform);
        
        if (isNewStyle) {
             
            ACCSocialStickerViewViewModel *hashTagViewConfig = [ACCSocialStickerViewViewModel constModelWithSocialType:ACCSocialStickerTypeHashTag effectModelInfo:effectModelExtraInfo];
            
            _textFont                   = hashTagViewConfig.textFont;
            _textColor                  = ACCResourceColor(ACCUIColorConstTextPrimary);// Groot默认不能是透明
            _textViewPadding            = hashTagViewConfig.textViewPadding;
            _tintColor                  = hashTagViewConfig.tintColor;
            _hashtagContentHeight       = hashTagViewConfig.contentHeight;
            _hashtagViewHeight          = _hashtagContentHeight;
            _backgroundColor            = hashTagViewConfig.backgroundColor;
            _iconUrl                    = [hashTagViewConfig.iconURL copy];
            _iconViewLeftInset          = hashTagViewConfig.iconViewLeftInset;
            _contentHorizontalMinMargin = hashTagViewConfig.contentHorizontalMinMargin;
            _contentHeight              = hashTagViewConfig.contentHeight;
            _borderHeight               = hashTagViewConfig.borderHeight;
            _cornerRadius               = hashTagViewConfig.cornerRadius;
            _textGradientColors         = hashTagViewConfig.textGradientColors;
            _gradientdiRect             = hashTagViewConfig.gradientdiRect;
            _textMaxWidth               = hashTagViewConfig.textMaxWidth;
            _hashtagIconFontImage       = hashTagViewConfig.iconFontImage;

        } else {

            UIFont *font = [ACCInteractionStickerFontHelper interactionFontWithFontName:ACCInteractionStcikerSocialFontName
                                                                               fontSize:28.f];
            if (!font) {
                font = [UIFont boldSystemFontOfSize:28.f];
            }
            _textFont = font;
            _textColor = ACCResourceColor(ACCUIColorConstTextPrimary);
            _textViewPadding = UIEdgeInsetsMake(0.f, 36.f, 0.f, 24.f);
            _tintColor = [UIColor acc_colorWithHex:@"#3CD0FF"];
            _iconViewLeftInset = 12.f;
            [self p_setupIconFont];
            _contentHorizontalMinMargin = 8.f;
            _contentHeight = 41.f;
            _borderHeight = 2.f;
            _textMaxWidth = (ACC_SCREEN_WIDTH - 2 * _contentHorizontalMinMargin - _textViewPadding.left - _textViewPadding.right);
        }
        
        _grootTextFont = [ACCFont() systemFontOfSize:16.0 weight:ACCFontWeightSemibold];
        _grootTintColor = [UIColor acc_colorWithHex:@"#42B22D"];
        _grootIconViewLeftInset = 13.3f;
        _grootTextViewPadding = UIEdgeInsetsMake(0.f, 32.f, 0.f, 15.f);
        _viewHeight = _borderHeight + _contentHeight;
        _grootTextMaxWidth = (ACC_SCREEN_WIDTH - 2 * _contentHorizontalMinMargin - _grootTextViewPadding.left - _grootTextViewPadding.right);
        
    }
    
    return self;
}

- (void)p_setupIconFont {
    // use only hashtag
    NSString *fontFileName = @"iconfont_hashtag";
    NSString *fontFileFullName = [NSString stringWithFormat:@"%@.ttf",fontFileName];
    NSURL *fontPath = [NSURL fileURLWithPath:ACCResourceFile(fontFileFullName)];
    
    BOOL fontFileExists = [[NSFileManager defaultManager] fileExistsAtPath:[fontPath path]];
    
    NSAssert(fontFileExists, @"Font file doesn't exist");
    
    NSString *fontName = @"hashtag";
    
    UIFont *iconFont = nil;
    if (fontFileExists) {
        iconFont = [ACCFont() iconFontWithPath:fontPath name:fontName size:28];
    }
    
    BOOL hasIconFont = !!iconFont;
    
    iconFont = iconFont ? : [UIFont boldSystemFontOfSize:28];
    
    _iconFont = iconFont;
    
    if (hasIconFont) {
        // glyph unicode is same
        _iconFontGlyph = @"\U0000e900";
    } else {
        _iconFontGlyph = @"#";
    }
}

@end

// The UI style is the same as the ACCSocialStickerView Class
@interface ACCGrootStickerView ()

/// flag
@property (nonatomic, assign) BOOL enableEdit;
@property (nonatomic, assign) CGPoint editCenter;
@property (nonatomic, assign) CGFloat currentScale;
@property (nonatomic, assign) CGFloat keyboardHeight;
@property (nonatomic, strong) NSString *extraInfo;

/// view
@property (nonatomic, strong) UITextField *inputTextView;
@property (nonatomic, strong) UILabel *iconFontLabel;
@property (nonatomic, strong) UIImageView *grootImageView;
@property (nonatomic, strong) UIView  *contentView;
@property (nonatomic, strong) UIView  *borderView;
@property (nonatomic, strong) UIView  *hashtagContentView;
@property (nonatomic, strong) UIImageView *hashtagImageView;
@property (nonatomic, strong) UILabel *inputTextColorLabel;
@property (nonatomic, strong) UITextField *hashtagInputTextView;

/// model
@property (nonatomic, strong) ACCGrootStickerViewViewModel *viewModel;
@property (nonatomic, assign) BOOL snapIsDummy;

@end

@implementation ACCGrootStickerView
@synthesize coordinateDidChange, stickerContainer = _stickerContainer, transparent = _transparent;
@synthesize stickerId = _stickerId;
@synthesize triggerDragDeleteCallback = _triggerDragDeleteCallback;

#pragma mark - life cycle

- (instancetype)initWithStickerModel:(ACCGrootStickerModel *)stickerModel
               grootStickerUniqueId:(NSString *)grootStickerUniqueId {
    NSParameterAssert(stickerModel != nil);

    if (self = [super init]) {
        _grootStickerUniqueId = (ACC_isEmptyString(grootStickerUniqueId) ?
                                  [NSString stringWithFormat:@"%@", @([[NSDate date] timeIntervalSince1970])] :
                                  [grootStickerUniqueId copy]);
        _stickerModel = [stickerModel copy];
        _extraInfo = [stickerModel.effectExtraInfo copy];
        [self setupUI];
        [self updateFrameWithGroot:(!stickerModel.selectedGrootStickerModel.isDummy && stickerModel.selectedGrootStickerModel)];
    }
    return self;
}

- (void)setupUI {
    ACCGrootStickerViewViewModel *viewModel = [[ACCGrootStickerViewViewModel alloc] initWitheffectModelInfo:self.extraInfo];
    self.viewModel = viewModel;
    self.backgroundColor = [UIColor clearColor];
    
    self.borderView = ({
        UIView *view = [UIView new];
        [self addSubview:view];
        view.backgroundColor = viewModel.tintColor;
        view.layer.cornerRadius = viewModel.contentHeight / 2.f;
        view.layer.masksToBounds = YES;
        view;
    });
    
    self.contentView = ({
        UIView *view = [UIView new];
        [self addSubview:view];
        view.backgroundColor = [UIColor whiteColor];
        view.layer.cornerRadius = viewModel.contentHeight / 2.f;
        view.layer.masksToBounds = YES;
        view;
    });
    
    self.hashtagContentView = ({
        UIView *view = [UIView new];
        [self addSubview:view];
        view.backgroundColor = viewModel.backgroundColor;
        view.layer.cornerRadius = viewModel.cornerRadius;
        view.layer.masksToBounds = YES;
        view;
    });
    
    self.iconFontLabel = ({
        UILabel *label = [UILabel new];
        [self.contentView addSubview:label];
        label.textColor = viewModel.tintColor;
        label.font = viewModel.iconFont;
        label.text = viewModel.iconFontGlyph;
        [label sizeToFit];
        label;
    });

    self.grootImageView = ({
        UIImageView *imageView = [[UIImageView alloc] initWithImage:ACCResourceImage(@"icon_sticker_groot")];
        [self.contentView addSubview:imageView];
        imageView;
    });
    
    self.hashtagImageView = ({
        UIImageView *imageView = [[UIImageView alloc] initWithImage:ACCResourceImage(@"icon_sticker_hashtag")];
        [self.hashtagContentView addSubview:imageView];
        if (ACCConfigBool(kConfigBool_sticker_support_poi_mention_hashtag_UI_uniform)) {
            if (viewModel.iconUrl) {
                NSArray *imageURLs = [NSArray arrayWithObject:viewModel.iconUrl];
                [ACCWebImage() imageView:imageView setImageWithURLArray:imageURLs placeholder:ACCResourceImage(@"icon_sticker_hashtag")];
            } else{
                imageView.image = ACCResourceImage(@"icon_sticker_hashtag");
            }
        }
        imageView;
    });
    
    self.hashtagInputTextView = ({
        UITextField *textField = [UITextField new];
        [self.hashtagContentView addSubview:textField];
        textField.tintColor =  ACCResourceColor(ACCUIColorConstPrimary);
        textField.font = viewModel.textFont;
        textField.textColor = viewModel.textColor;
        textField.backgroundColor = [UIColor clearColor];
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.userInteractionEnabled = NO;
        textField;
    });
 
    self.inputTextView = ({
        UITextField *textField = [UITextField new];
        [self.contentView addSubview:textField];
        textField.tintColor =  ACCResourceColor(ACCUIColorConstPrimary);
        textField.font = viewModel.textFont;
        textField.textColor = viewModel.textColor;
        textField.backgroundColor = [UIColor clearColor];
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.userInteractionEnabled = NO;
        textField;
    });

    ACCGrootDetailsStickerModel *selectedModel = self.stickerModel.selectedGrootStickerModel;
    self.inputTextView.text = selectedModel.speciesName;
}

- (void)updateFrameWithGroot:(BOOL)isGroot {
    ACCGrootStickerViewViewModel *viewModel = self.viewModel;
    if (isGroot) {
        self.iconFontLabel.hidden = YES;
        self.grootImageView.hidden = NO;
        self.hashtagContentView.hidden = YES;
        self.contentView.hidden = NO;
        self.grootImageView.acc_left = viewModel.grootIconViewLeftInset;
        self.grootImageView.acc_centerY = viewModel.contentHeight / 2.f;
        self.inputTextView.font = viewModel.grootTextFont;
        self.borderView.backgroundColor = viewModel.grootTintColor;

    } else {
        if (ACCConfigBool(kConfigBool_sticker_support_poi_mention_hashtag_UI_uniform)) {
            self.iconFontLabel.hidden = YES;
            self.grootImageView.hidden = YES;
            self.hashtagContentView.hidden = NO;
            self.contentView.hidden = YES;
            self.hashtagImageView.acc_left = viewModel.iconViewLeftInset;
            self.hashtagImageView.acc_centerY = viewModel.contentHeight / 2.f;
            self.hashtagInputTextView.font = viewModel.textFont;

        } else {
            self.iconFontLabel.hidden = NO;
            self.grootImageView.hidden = YES;
            self.hashtagContentView.hidden = YES;
            self.contentView.hidden = NO;
            self.iconFontLabel.acc_left    = viewModel.iconViewLeftInset;
            self.iconFontLabel.acc_centerY = viewModel.contentHeight / 2.f;
            self.inputTextView.font = viewModel.textFont;
            self.borderView.backgroundColor = viewModel.tintColor;

        }
    }

    [self.inputTextView sizeToFit];
    [self.hashtagInputTextView sizeToFit];
    CGSize textInputSize = self.inputTextView.acc_size;
    if (!isGroot && ACCConfigBool(kConfigBool_sticker_support_poi_mention_hashtag_UI_uniform)) {
        textInputSize = self.hashtagInputTextView.acc_size;
    }
    CGFloat textMaxWidth = isGroot ? viewModel.grootTextMaxWidth : viewModel.textMaxWidth;
    BOOL isTextOverMaxWidth = textInputSize.width > textMaxWidth;
    textInputSize.width = MIN(textMaxWidth, textInputSize.width);
    
    UIEdgeInsets  textViewPadding = isGroot ? viewModel.grootTextViewPadding : viewModel.textViewPadding;

    /// only recongition sticker
    __block CGFloat selfWidth = textInputSize.width + textViewPadding.left + textViewPadding.right;
    __block CGFloat selfHeight = isGroot ? viewModel.viewHeight : viewModel.hashtagViewHeight;
    [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.tag == RECOGNITION_GROOT_TAG && isGroot){
            obj.hidden = NO;
            self.contentView.hidden = YES;
            self.borderView.hidden = YES;
            UIView *recognitionGrootView = obj;
            selfWidth = recognitionGrootView.acc_width;
            selfHeight = recognitionGrootView.acc_height;
            *stop = YES;
        }
    }];

    self.bounds = CGRectMake(0, 0, selfWidth, selfHeight);

    self.contentView.frame = CGRectMake(0, 0, selfWidth, viewModel.contentHeight);
    self.borderView.frame  = CGRectMake(0, viewModel.borderHeight, selfWidth, viewModel.contentHeight);
    
    self.hashtagContentView.frame = CGRectMake(0, 0, selfWidth, viewModel.hashtagContentHeight);
    
    // may case flashing if always set adjusts size to fit
    self.inputTextView.adjustsFontSizeToFitWidth = isTextOverMaxWidth;
    // align right to content view, reserve 'edit spacing'
    self.inputTextView.acc_size    = CGSizeMake(selfWidth - textViewPadding.left, textInputSize.height);
    self.inputTextView.acc_centerY = viewModel.contentHeight / 2.f;
    self.inputTextView.acc_left    = textViewPadding.left;
    
    self.hashtagInputTextView.adjustsFontSizeToFitWidth = isTextOverMaxWidth;
    self.hashtagInputTextView.acc_size    = CGSizeMake(selfWidth - textViewPadding.left, textInputSize.height);
    self.hashtagInputTextView.acc_centerY = viewModel.hashtagContentHeight / 2.f;
    self.hashtagInputTextView.acc_left    = textViewPadding.left;
    
    // fix scroll flash when first edit
    [self.inputTextView setNeedsLayout];
    [self.inputTextView layoutIfNeeded];
    
    [self.hashtagInputTextView setNeedsLayout];
    [self.hashtagInputTextView layoutIfNeeded];

    ACCBLOCK_INVOKE(self.coordinateDidChange);
    
    if (self.enableEdit) {
        [self updateEdtingFrames];
    }
}

- (UIColor *)gradientColorImageFromColors:(NSArray *)colors imageSize:(CGSize)imgSize gradientRect:(NSInteger)gradientdirect {
    
    UIGraphicsBeginImageContextWithOptions(imgSize, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradientRef = CGGradientCreateWithColors(colorSpaceRef, (__bridge CFArrayRef)colors, NULL);
    CGPoint startPoint = CGPointZero;
    CGPoint endPoint = gradientdirect == 0 ? CGPointMake(imgSize.width, 0.0) : CGPointMake(0.0, imgSize.height);
    CGContextDrawLinearGradient(context, gradientRef, startPoint, endPoint,  kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    
    CGColorSpaceRelease(colorSpaceRef);
    CGGradientRelease(gradientRef);
    UIGraphicsEndImageContext();
    
    return [UIColor colorWithPatternImage:gradientImage];
}

- (void)updateEdtingFrames {
    
    CGPoint editCenter = CGPointMake(ACC_SCREEN_WIDTH * 0.5, ACC_SCREEN_HEIGHT * 0.27 - 26);
    if (@available(iOS 9.0, *)) {
        editCenter = [[[UIApplication sharedApplication].delegate window] convertPoint:editCenter toView:[self.stickerContainer containerView]];
    }

    CGFloat del = editCenter.y + self.inputTextView.frame.size.height * 0.5 - (ACC_SCREEN_HEIGHT - self.keyboardHeight);

    if (del > 0) {
        self.center = CGPointMake(ACC_SCREEN_WIDTH / 2.f, editCenter.y - 52 - del);
    } else {
        self.center = CGPointMake(ACC_SCREEN_WIDTH / 2.f, editCenter.y - 52);
    }

    _editCenter = self.center;
}

#pragma mark - public

- (void)transportToEditWithSuperView:(UIView *)superView
                           animation:(void (^)(void))animationBlock
          selectedViewAnimationBlock:(void (^)(void))selectedViewAnimationBlock
                   animationDuration:(CGFloat)duration {
    
    self.enableEdit = YES;
    
    CGPoint center = [self.superview convertPoint:self.center toView:superView];
    CGAffineTransform transform = self.superview.transform; // Unreasonably design, refactor in the future
    [self removeFromSuperview];
    [superView addSubview:self];
    self.center = center;
    self.transform = transform;
    
    [UIView animateWithDuration:duration animations:^{
        self.transform = CGAffineTransformIdentity;
        BOOL  isGroot = YES;
        if (!self.stickerModel.selectedGrootStickerModel) {
            isGroot = !self.snapIsDummy;
        } else {
            isGroot = !self.stickerModel.selectedGrootStickerModel.isDummy;
        }
        [self updateFrameWithGroot:isGroot];
        if (animationBlock) {
            animationBlock();
        }
    } completion:^(BOOL finished) {
        
    }];
    
    // groot选择贴纸面板动效
    [CATransaction begin];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithControlPoints:0 : 0.4 : 0.2 : 1.0]];
    [UIView animateWithDuration:0.35 animations:^{
        if (selectedViewAnimationBlock) {
            selectedViewAnimationBlock();
        }
    } completion:^(BOOL finished) {
        
    }];
    [CATransaction commit];
}

- (void)restoreToSuperView:(UIView *)superView
         animationDuration:(CGFloat)duration
            animationBlock:(void (^)(void))animationBlock
selectedViewAnimationBlock:(void (^)(void))selectedViewAnimationBlock
                completion:(void (^)(void))completion {
    
    self.enableEdit = NO;
    
    CGPoint center = [self.superview convertPoint:self.center toView:superView];
    CGAffineTransform transform = superView.transform;
    transform = CGAffineTransformInvert(transform);
    [self removeFromSuperview];
    [superView addSubview:self];
    self.center = center;
    self.transform = transform;
    
    [UIView animateWithDuration:duration animations:^{
        self.transform = CGAffineTransformIdentity;
        [self contentDidUpdateToScale:self.currentScale];
        BOOL  isGroot = YES;
        if (!self.stickerModel.selectedGrootStickerModel) {
            isGroot = !self.snapIsDummy;
        } else {
            isGroot = !self.stickerModel.selectedGrootStickerModel.isDummy;
        }
        [self updateFrameWithGroot:isGroot];
        if (animationBlock) {
            animationBlock();
        }
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];
    
    // groot选择贴纸面板动效
    [CATransaction begin];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithControlPoints:0.3 : 0 : 0.9 : 0.6]];
    [UIView animateWithDuration:0.16 animations:^{
        if (selectedViewAnimationBlock) {
            selectedViewAnimationBlock();
        }
    } completion:^(BOOL finished) {
        
    }];
    [CATransaction commit];
}

- (void)configGrootDetailsStickerModel:(ACCGrootDetailsStickerModel *)grootStickerModel snapIsDummy:(BOOL)snapIsDummy {
    self.stickerModel.selectedGrootStickerModel = grootStickerModel;
    ACCGrootStickerViewViewModel *viewModel = self.viewModel;
    self.snapIsDummy = snapIsDummy;
    if (!grootStickerModel) {
        return;
    }
    if (grootStickerModel.isDummy) {
        // #求高手鉴定  话题贴纸样式
        self.inputTextView.text = @"求高手鉴定";
        self.hashtagInputTextView.text = @"求高手鉴定";
        if (ACCConfigBool(kConfigBool_sticker_support_poi_mention_hashtag_UI_uniform)) {
            self.hashtagInputTextView.textColor = [self gradientColorImageFromColors:viewModel.textGradientColors imageSize:self.hashtagInputTextView.bounds.size gradientRect:viewModel.gradientdiRect];
        } else {
            self.inputTextView.textColor = ACCResourceColor(ACCUIColorConstTextPrimary);
        }
        [self updateFrameWithGroot:NO];
    } else {
        NSString *speciesName = grootStickerModel.speciesName;
        self.inputTextView.text = speciesName ?: @"";
        self.inputTextView.textColor = ACCResourceColor(ACCUIColorConstTextPrimary);
        // Groot 样式
        [self updateFrameWithGroot:YES];
    }
}

- (BOOL)isFromRecord {
    __block BOOL fromRecord = NO;
    [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.tag == RECOGNITION_GROOT_TAG){
            fromRecord = YES;
            *stop = YES;
        }
    }];
    return fromRecord;
}

#pragma mark - ACCStickerCopyingProtocol

- (id)copyForContext:(id)contextId {

    if ([ACCRecognitionGrootConfig enabled]){
        ACCRecognitionStickerViewType type = (ACCRecognitionStickerViewType)([ACCRecognitionGrootConfig stickerStyle]);
        let view = [ACCRecognitionGrootStickerViewFactory viewWithType:type];
        [view configWithModel:self.stickerModel.selectedGrootStickerModel.copy];
        view.tag = RECOGNITION_GROOT_TAG;
        view.alpha = 1;
        let container = [[ACCGrootStickerView alloc] initWithStickerModel:[self.stickerModel copy]
                                            grootStickerUniqueId:[self.grootStickerUniqueId copy]];

        [[container subviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.hidden = YES;
        }];
        [container addSubview:view];
        container.frame = self.frame;

        return container;
    }else{
        return [[ACCGrootStickerView alloc] initWithStickerModel:[self.stickerModel copy]
                                            grootStickerUniqueId:[self.grootStickerUniqueId copy]];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    ACCBLOCK_INVOKE(self.coordinateDidChange);
}

#pragma mark - ACCStickerContentProtocol

- (void)contentDidUpdateToScale:(CGFloat)scale {
    // only recongition groot sticker
    __block BOOL hasGrootSubView = NO;
    [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj conformsToProtocol:@protocol(ACCStickerContentProtocol)]) {
            [(id<ACCStickerContentProtocol>)obj contentDidUpdateToScale:scale];
            hasGrootSubView = YES;
            *stop = YES;
        }
    }];
    if (hasGrootSubView) {
        return;
    }
    scale = MAX(1, scale);
    _currentScale = scale;
    CGFloat contentScaleFactor = MIN(3, scale) * [UIScreen mainScreen].scale;
    BOOL isNewStyle = ACCConfigBool(kConfigBool_sticker_support_poi_mention_hashtag_UI_uniform);
    if (isNewStyle) {
        self.hashtagImageView.contentScaleFactor = contentScaleFactor;
        self.hashtagInputTextView.contentScaleFactor = contentScaleFactor;
        [ACCStickerUtils applyScale:contentScaleFactor toLayer:self.hashtagImageView.layer];
        [ACCStickerUtils applyScale:contentScaleFactor toLayer:self.hashtagInputTextView.layer];
    } else {
        self.iconFontLabel.contentScaleFactor = contentScaleFactor;
        self.grootImageView.contentScaleFactor = contentScaleFactor;
        [ACCStickerUtils applyScale:contentScaleFactor toLayer:self.iconFontLabel.layer];
        [ACCStickerUtils applyScale:contentScaleFactor toLayer:self.grootImageView.layer];
    }
    self.inputTextView.contentScaleFactor = contentScaleFactor;
    [ACCStickerUtils applyScale:contentScaleFactor toLayer:self.inputTextView.layer]; 
}

#pragma mark - ACCStickerEditContentProtocol
- (void)setTransparent:(BOOL)transparent
{
    _transparent = transparent;
    
    self.alpha = transparent? 0.5: 1.0;
}

@end
