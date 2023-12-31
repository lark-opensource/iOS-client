//
//  ACCSocialStickerView.m
//  CameraClient-Pods-Aweme-CameraResource_base
//
//  Created by qiuhang on 2020/8/5.
//

#import "ACCSocialStickerView.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKitSticker/ACCStickerUtils.h>
#import "ACCSocialStickerBindingController.h"
#import "ACCInteractionStickerFontHelper.h"
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/NSString+CameraClientResource.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import "ACCConfigKeyDefines.h"
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import "ACCSocialStickerHandler.h"
#import <CreativeKit/ACCWebImageProtocol.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>


@interface ACCSocialStickerView () <UIGestureRecognizerDelegate, ACCSocialStickerBindingDelegate>

/// flag
@property (nonatomic, assign) BOOL enableEdit;
@property (nonatomic, assign) CGPoint editCenter;
@property (nonatomic, assign) CGFloat currentScale;
@property (nonatomic, assign) CGFloat keyboardHeight;

/// view
@property (nonatomic, strong) UITextField *inputTextView;
@property (nonatomic, strong) UILabel *iconFontLabel;
@property (nonatomic, strong) UIView  *contentView;
@property (nonatomic, strong) UIView  *borderView;
@property (nonatomic, strong) UIImageView *iconFontImageView;

/// model
@property (nonatomic, strong) ACCSocialStickerViewViewModel *viewModel;
@property (nonatomic, strong) ACCSocialStickerBindingController * bindingController;

///可配置参数
@property (nonatomic, strong) NSString *extra;

@end

@implementation ACCSocialStickerView
@synthesize coordinateDidChange, stickerContainer = _stickerContainer, transparent = _transparent;
@synthesize stickerId = _stickerId;
@synthesize triggerDragDeleteCallback = _triggerDragDeleteCallback;

#pragma mark - life cycle
- (instancetype)initWithStickerModel:(ACCSocialStickerModel *)stickerModel
               socialStickerUniqueId:(NSString *)socialStickerUniqueId {
    
    NSParameterAssert(stickerModel != nil);

    if (self = [super init]) {
        _socialStickerUniqueId = (ACC_isEmptyString(socialStickerUniqueId) ?
                                  [NSString stringWithFormat:@"%@", @([[NSDate date] timeIntervalSince1970])] :
                                  [socialStickerUniqueId copy]);
        _stickerModel = [stickerModel copy];
        _extra = [stickerModel.extraInfo copy];
        [self setupUI];
        [self setupData];
    }
    return self;
}

#pragma mark - setup
- (void)setupData {
    
    self.bindingController = [[ACCSocialStickerBindingController alloc] initWithTextInput:self.inputTextView stickerModel:self.stickerModel delegate:self];
}

- (void)setupUI {
    
    ACCSocialStickerViewViewModel *viewModel = [ACCSocialStickerViewViewModel constModelWithSocialType:self.stickerType effectModelInfo:self.extra];
    self.viewModel = viewModel;
    
    self.backgroundColor = [UIColor clearColor];
    BOOL isMention = (self.stickerType == ACCSocialStickerTypeMention);
    
    if (ACCConfigBool(kConfigBool_sticker_support_poi_mention_hashtag_UI_uniform)) {
            self.contentView = ({
                
                UIView *view = [UIView new];
                [self addSubview:view];
                view.backgroundColor = viewModel.backgroundColor;
                if (@available(iOS 13.0, *)) {
                    view.layer.cornerRadius = viewModel.cornerRadius;
                    view.layer.cornerCurve = kCACornerCurveContinuous;
                } else {
                    view.layer.cornerRadius = viewModel.cornerRadius;
                }
                view.layer.masksToBounds = YES;
                view;
            });
            
            self.iconFontImageView = ({

                UIImageView *imageView = [[UIImageView alloc] initWithImage:ACCResourceImage(@"icon_sticker_hashtag")];
                [self.contentView addSubview:imageView];
                if (ACCConfigBool(kConfigBool_sticker_support_poi_mention_hashtag_UI_uniform)){
                    if (viewModel.iconURL) {
                        NSArray *imageURLs = [NSArray arrayWithObject:viewModel.iconURL];
                        [ACCWebImage() imageView:imageView setImageWithURLArray:imageURLs placeholder:isMention ? ACCResourceImage(@"icon_sticker_mention") : ACCResourceImage(@"icon_sticker_hashtag")];
                    } else{
                        imageView.image = isMention ? ACCResourceImage(@"icon_sticker_mention") : ACCResourceImage(@"icon_sticker_hashtag");
                    }
                }
                imageView;
            });
            
            self.inputTextView = ({
                
                UITextField *textField = [UITextField new];
                [self.contentView addSubview:textField];
                textField.tintColor =  ACCResourceColor(ACCUIColorConstPrimary);;
                textField.font = viewModel.textFont;
                textField.textColor = viewModel.textColor;
                textField.backgroundColor = [UIColor clearColor];
                textField.autocorrectionType = UITextAutocorrectionTypeNo;
                textField.userInteractionEnabled = NO;
                textField;
            });
            
        }else {
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
            
            self.iconFontLabel = ({
                    
                UILabel *label = [UILabel new];
                [self.contentView addSubview:label];
                label.text = viewModel.iconFontGlyph;
                label.textColor = viewModel.tintColor;
                label.font = viewModel.iconFont;
                [label sizeToFit];
                label;
            });
            
            self.inputTextView = ({
                
                UITextField *textField = [UITextField new];
                [self.contentView addSubview:textField];
                textField.tintColor =  ACCResourceColor(ACCUIColorConstPrimary);;
                textField.font = viewModel.textFont;
                textField.textColor = viewModel.textColor;
                textField.backgroundColor = [UIColor clearColor];
                textField.autocorrectionType = UITextAutocorrectionTypeNo;
                textField.userInteractionEnabled = NO;
                textField;
            });
        }
}

#pragma mark - public getter
- (ACCSocialStickerType)stickerType {
    return self.stickerModel.stickerType;
}

- (NSString *)currentSearchKeyword {
    return [self.stickerModel.contentString copy];
}

- (ACCSocialStickeMentionBindingModel *)currentMentionBindingModel {
    return [self.stickerModel hasVaildMentionBindingData] ? self.stickerModel.mentionBindingModel : nil;
}

- (void)setEnableEdit:(BOOL)enableEdit
{
    _enableEdit = enableEdit;
    
    _inputTextView.userInteractionEnabled = enableEdit;
}

#pragma mark - update
- (void)updateFrame {
    
    ACCSocialStickerViewViewModel *viewModel = self.viewModel;
    
    // case: placeholder.length > text.length, clean  before sizeToFit called if need
    self.inputTextView.attributedPlaceholder = (ACC_isEmptyString(self.inputTextView.text) ?
                                                viewModel.textPlaceholder : nil);
    
    [self.inputTextView sizeToFit];
    CGSize textInputSize = self.inputTextView.acc_size;
    BOOL isTextOverMaxWidth = textInputSize.width > viewModel.textMaxWidth;
    textInputSize.width = MIN(viewModel.textMaxWidth, textInputSize.width);
    CGFloat selfWidth = textInputSize.width + viewModel.textViewPadding.left + viewModel.textViewPadding.right;
    
    self.bounds = CGRectMake(0, 0, selfWidth, viewModel.viewHeight);

    self.contentView.frame = CGRectMake(0, 0, selfWidth, viewModel.contentHeight);
    self.borderView.frame  = CGRectMake(0, viewModel.borderHeight, selfWidth, viewModel.contentHeight);
    
    self.iconFontLabel.acc_left    = viewModel.iconViewLeftInset;
    self.iconFontLabel.acc_centerY = viewModel.contentHeight / 2.f;
    
    self.iconFontImageView.acc_left    = viewModel.iconViewLeftInset;
    self.iconFontImageView.acc_centerY = viewModel.contentHeight / 2.f;
    
    // may case flashing if always set adjusts size to fit
    self.inputTextView.adjustsFontSizeToFitWidth = isTextOverMaxWidth;
    // align right to content view, reserve 'edit spacing'
    self.inputTextView.acc_size    = CGSizeMake(selfWidth - viewModel.textViewPadding.left, textInputSize.height);
    self.inputTextView.acc_centerY = viewModel.contentHeight / 2.f;
    self.inputTextView.acc_left    = viewModel.textViewPadding.left;
    
    if (ACCConfigBool(kConfigBool_sticker_support_poi_mention_hashtag_UI_uniform)) {
        self.inputTextView.textColor = [self gradientColorImageFromColors:viewModel.textGradientColors imageSize:self.inputTextView.bounds.size gradientRect:viewModel.gradientdiRect];
    }
    // fix scroll flash when first edit
    [self.inputTextView setNeedsLayout];
    [self.inputTextView layoutIfNeeded];

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

#pragma mark - text handler
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    // e.g. third party keyboard click hide keyboad button
    ACCBLOCK_INVOKE(self.onDidEndEditing);
}

#pragma mark - binding controller delegate
- (void)bindingControllerOnMentionBindingDataChanged:(ACCSocialStickerBindingController *)bindingController {
    ACCBLOCK_INVOKE(self.onMentionBindingDataChanged);
}

- (void)bindingController:(ACCSocialStickerBindingController *)bindingController
            onTextChanged:(UITextField *)textField {
    [self updateFrame];
}

- (void)bindingControllerOnSearchKeywordChanged:(ACCSocialStickerBindingController *)bindingController {
    ACCBLOCK_INVOKE(self.onSearchKeywordChanged);
}

#pragma mark - binding update
- (BOOL)bindingWithMentionModel:(ACCSocialStickeMentionBindingModel *)bindingUserModel {
    return  [self.bindingController bindingWithMentionModel:bindingUserModel];
}

- (BOOL)bindingWithHashTagModel:(ACCSocialStickeHashTagBindingModel *)hashTagModel {
    return [self.bindingController bindingWithHashTagModel:hashTagModel];
}

#pragma mark - transport
- (void)bindInputAccessoryView:(__kindof UIView *)accessoryView {
    self.inputTextView.inputAccessoryView = accessoryView;
}

- (void)updateKeyboardHeight:(CGFloat)height {
    self.keyboardHeight = height;
    [self updateFrame];
}

- (void)transportToEditWithSuperView:(UIView *)superView
                           animation:(void (^)(void))animationBlock
                   animationDuration:(CGFloat)duration {
    
    self.enableEdit = YES;

    CGPoint center = [self.superview convertPoint:self.center toView:superView];
    CGAffineTransform transform = self.superview.transform; // Unreasonably design, refactor in the future
    [self removeFromSuperview];
    [superView addSubview:self];
    self.center = center;
    self.transform = transform;

    [UIView animateWithDuration:duration animations:^{
        [self.inputTextView becomeFirstResponder];
        self.transform = CGAffineTransformIdentity;
        [self updateFrame];
        if (animationBlock) {
            animationBlock();
        }
    } completion:^(BOOL finished) {
        
    }];
}

- (void)restoreToSuperView:(UIView *)superView
         animationDuration:(CGFloat)duration
            animationBlock:(void (^)(void))animationBlock
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
        if (animationBlock) {
            animationBlock();
        }
        [self contentDidUpdateToScale:self.currentScale];
        [self updateFrame];
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];
}


#pragma mark - ACCStickerCopyingProtocol
- (id)copyForContext:(id)contextId {
    return [[ACCSocialStickerView alloc] initWithStickerModel:[self.stickerModel copy]
                                        socialStickerUniqueId:[self.socialStickerUniqueId copy]];
}

- (void)updateWithInstance:(id)instance context:(id)contextId {}

#pragma mark - ACCStickerContentProtocol
- (void)contentDidUpdateToScale:(CGFloat)scale {
    
    scale = MAX(1, scale);
    _currentScale = scale;
    CGFloat contentScaleFactor = MIN(3, scale) * [UIScreen mainScreen].scale;
    if (ACCConfigBool(kConfigBool_sticker_support_poi_mention_hashtag_UI_uniform)) {
        self.iconFontImageView.contentScaleFactor = contentScaleFactor;
        [ACCStickerUtils applyScale:contentScaleFactor toLayer:self.iconFontImageView.layer];;
    } else {
        self.iconFontLabel.contentScaleFactor = contentScaleFactor;
        [ACCStickerUtils applyScale:contentScaleFactor toLayer:self.iconFontLabel.layer];
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

#pragma mark - ACCSocialStickerViewViewModel
@implementation ACCSocialStickerViewViewModel

- (instancetype)initWithSocialType:(ACCSocialStickerType)type effectModelInfo:(NSString *)effectModelExtraInfo {
    
    if (self = [super init]) {
        
        BOOL isMention = (type == ACCSocialStickerTypeMention);
        BOOL isNewStyle = ACCConfigBool(kConfigBool_sticker_support_poi_mention_hashtag_UI_uniform);
        
        if (isNewStyle) {
            
            _textColor = [UIColor clearColor];
            _textViewPadding = isMention ? UIEdgeInsetsMake(6.f, 36.f, 6.f, 14.f) : UIEdgeInsetsMake(6.f, 36.f, 6.f, 14.f);
            _tintColor = [UIColor clearColor];
            _contentHeight = 44.f;
            _viewHeight = _contentHeight;
            _backgroundColor = [UIColor whiteColor];
            UIFont *font = [ACCFont() acc_systemFontOfSize:23 weight:ACCFontWeightMedium];
            _textFont = font;
            _textGradientColors = [NSArray arrayWithObjects:(id)[[UIColor acc_colorWithHex:isMention ? @"#0077E4" : @"#FF642B"] CGColor], (id)[[UIColor acc_colorWithHex:isMention ? @"#4900E5" : @"#FF184F"]CGColor], nil];
            _gradientdiRect = 0;
            _cornerRadius = 8.f;
                    
            UIImage *image = isMention ? ACCResourceImage(@"icon_sticker_mention") : ACCResourceImage(@"icon_sticker_hashtag");
            _iconFontImage = image;
            
            if (!ACC_isEmptyString(effectModelExtraInfo)) {
                
                NSDictionary *jsonDic     = [effectModelExtraInfo acc_jsonValueDecoded];
                NSString *textFont        = [jsonDic btd_stringValueForKey:@"itextfont"];
                NSString *textColorFrom   = [jsonDic btd_stringValueForKey:@"textcolorfrom"];
                NSString *textColorTo     = [jsonDic btd_stringValueForKey:@"textcolorto"];
                NSString *gradientdirect  = [jsonDic btd_stringValueForKey:@"gradientdirect"];
                NSString *cornerRadius    = [jsonDic btd_stringValueForKey:@"radius"];
                NSString *iconUrl         = [jsonDic btd_stringValueForKey:@"iconurl"];
                NSString *backgroundColor = [jsonDic btd_stringValueForKey:@"backgroundcolor"];
                
                if (!ACC_isEmptyString(textFont)) {
                    
                    UIFont *font = [ACCInteractionStickerFontHelper interactionFontWithFontName:textFont fontSize:23.f];
                    if (font) {
                        _textFont = font;
                    }
                }

                if (!ACC_isEmptyString(backgroundColor)) {
                    _backgroundColor = [UIColor acc_colorWithHex:backgroundColor];
                }
                
                if (!ACC_isEmptyString(cornerRadius)) {
                    _cornerRadius = [cornerRadius floatValue];
                }
                
                if (!ACC_isEmptyString(textColorFrom) && !ACC_isEmptyString(textColorTo)) {
                    
                    UIColor *gradientColorFrom = [UIColor acc_colorWithHex:textColorFrom];
                    UIColor *gradientColorTo = [UIColor acc_colorWithHex:textColorTo];
                    if (gradientColorFrom && gradientColorTo) {
                        _textGradientColors = [NSArray arrayWithObjects:(id)[gradientColorFrom CGColor], (id)[gradientColorTo CGColor], nil];
                    }
                }

                if (!ACC_isEmptyString(gradientdirect)) {
                    _gradientdiRect = [gradientdirect integerValue];
                }

                if (!ACC_isEmptyString(iconUrl)) {
                    _iconURL = [iconUrl copy];
                }
            }
            
            NSString *placeholdString = ACCLocalizedString(isMention ? @"creation_edit_sticker_mention" : @"creation_edit_sticker_hashtag", nil);
            UIColor *placeholderColor = ACCResourceColor(ACCUIColorConstTextSecondary) ? : [UIColor blackColor];
            placeholderColor = [placeholderColor colorWithAlphaComponent:0.34f];
            _textPlaceholder = [[NSAttributedString alloc] initWithString:placeholdString ? : @""
                                                               attributes:@{NSFontAttributeName : _textFont?:font,
                                                                                    NSForegroundColorAttributeName : placeholderColor}];
            
        } else {
            
            UIFont *font = font = [ACCInteractionStickerFontHelper interactionFontWithFontName:ACCInteractionStcikerSocialFontName fontSize:28.f];
            if (!font) {
                font = [UIFont boldSystemFontOfSize:28.f];
            }
            _textFont = font;
            _cornerRadius = 8.f;
            NSString *placeholdString = ACCLocalizedString(isMention ? @"creation_edit_sticker_mention" : @"creation_edit_sticker_hashtag", nil);
            UIColor *placeholderColor = ACCResourceColor(ACCUIColorConstTextSecondary) ? : [UIColor blackColor];
            placeholderColor = [placeholderColor colorWithAlphaComponent:0.34f];
            _textPlaceholder = [[NSAttributedString alloc] initWithString:placeholdString ? : @""
                                                                       attributes:@{NSFontAttributeName : font,
                                                                                    NSForegroundColorAttributeName : placeholderColor}];
            
            _textColor = [UIColor acc_colorWithHex:@"#323031"];
            _textViewPadding = isMention ? UIEdgeInsetsMake(0.f, 42.f, 0.f, 18.f) : UIEdgeInsetsMake(0.f, 36.f, 0.f, 24.f);
            _tintColor = [UIColor acc_colorWithHex:isMention ? @"#FF478D" : @"#3CD0FF"];
            _contentHeight = 40.f;
            _borderHeight = 3.f;
            _viewHeight = _borderHeight + _contentHeight;
        }
        _iconViewLeftInset = isMention ? 12.f : 12.f;
        [self p_setupIconFontWithIsMention:isMention];
        _contentHorizontalMinMargin = 8.f;
        _textMaxWidth = (ACC_SCREEN_WIDTH - 2 * _contentHorizontalMinMargin - _textViewPadding.left - _textViewPadding.right);
    }
    
    return self;
}

///通过IESEffectModel.extra字段信息设置viewModel
+ (instancetype)constModelWithSocialType:(ACCSocialStickerType)type effectModelInfo:(NSString *)effectModelExtraInfo{
    return [[ACCSocialStickerViewViewModel alloc] initWithSocialType:type effectModelInfo:effectModelExtraInfo];
}

- (void)p_setupIconFontWithIsMention:(BOOL)isMention {
    
    NSString *fontFileName = isMention ? @"iconfont_mention" : @"iconfont_hashtag";
    NSString *fontFileFullName = [NSString stringWithFormat:@"%@.ttf",fontFileName];
    NSURL *fontPath = [NSURL fileURLWithPath:ACCResourceFile(fontFileFullName)];
    
    BOOL fontFileExists = [[NSFileManager defaultManager] fileExistsAtPath:[fontPath path]];
    
    NSAssert(fontFileExists, @"Font file doesn't exist");
    
    NSString *fontName = isMention ? @"mention" : @"hashtag";
    
    UIFont *iconFont = nil;
    if (fontFileExists) {
        iconFont = [ACCFont() iconFontWithPath:fontPath name:fontName size:28];
    }
    
    BOOL hasIconFont = !!iconFont;
    
    iconFont = iconFont ? : [UIFont boldSystemFontOfSize:28];
    
    _iconFont = iconFont;
    
    if (hasIconFont) {
        // glyph unicode is same
        _iconFontGlyph = isMention ? @"\U0000e900" : @"\U0000e900";
    } else {
        _iconFontGlyph = isMention ? @"@" : @"#";
    }
}

@end
