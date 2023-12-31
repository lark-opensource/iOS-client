//
//  ACCTextStickerView.m
//  CameraClient
//
//  Created by Yangguocheng on 2020/7/16.
//

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCColorNameDefines.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import "AWEStoryColorChooseView.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitArch/ACCCustomFontProtocol.h>
#import <CreativeKitSticker/ACCStickerUtils.h>
#import "ACCTextStickerView+Internal.h"

#import <CameraClient/AWEStoryTextImageModel+WidthLimit.h>
#import <CreativeKitSticker/ACCStickerProtocol.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import "ACCTextStickerInputController.h"
#import <CreativeKit/NSArray+ACCAdditions.h>

static CGFloat const kACCTextStickerBGColorLeftMargin = 12;
static CGFloat const kACCTextStickerBGColorTopMargin = 6;
static CGFloat const kACCTextStickeTextViewContainerInset = 14;

static CGFloat kACCTextStickerBGTextViewLeftMargin = 32;

@interface ACCTextStickerView () <UIGestureRecognizerDelegate, ACCTextViewDelegate, ACCTextStickerInputControllerDelegate>

@property (nonatomic, assign) BOOL enableEdit;
@property (nonatomic, assign) BOOL fromClickEdit;
@property (nonatomic, assign) CGFloat minCenterCanBeMoved;

@property (nonatomic, strong) ACCTextStickerTextView *textView;

@property (nonatomic, assign) CGFloat defaultFontSize;

@property (nonatomic, strong) AWEStoryTextImageModel *textModel;

@property (nonatomic, assign) CGPoint editCenter;
@property (nonatomic, assign) CGFloat currentScale;

@property (nonatomic, assign, readonly) BOOL enableTextStickerSocialBind;

@property (nonatomic, assign, readonly) ACCTextStickerViewAbilityOptions viewOptions;

@end

@implementation ACCTextStickerView
@synthesize transparent = _transparent;
@synthesize stickerId = _stickerId;
@synthesize triggerDragDeleteCallback = _triggerDragDeleteCallback;

- (instancetype)initWithTextInfo:(AWEStoryTextImageModel *)model options:(ACCTextStickerViewAbilityOptions)options
{
    self = [super init];
    if (self) {
        _viewOptions = options;
        _textModel = model;
        _fromClickEdit = NO;
        _minCenterCanBeMoved = 0;
        _enableTextStickerSocialBind = (options & ACCTextStickerViewAbilityOptionsSupportSocial);
        self.defaultFontSize = 28.f;
        if (!ACC_FLOAT_EQUAL_ZERO(model.fontSize)) {
            self.defaultFontSize = model.fontSize;
        }
        self.textView.attributedText = [[NSAttributedString alloc] initWithString:model.content ? : @""];
        
        [self setupSocialBindControllerIfEnableWithinitialExtraInfos:model.extraInfos];
        
        self.textStickerId = [NSString stringWithFormat:@"%@", @([[NSDate date] timeIntervalSince1970])];
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
        [self addGestureRecognizer:panGesture];
        
        [self addSubview:self.textView];
        
        [self updateDisplay];
    }
    return self;
}

- (void)updateFrame
{
    self.textView.backgroundColor = [UIColor clearColor];
    CGSize textViewSize = [self.textView sizeThatFits:CGSizeMake(ACC_SCREEN_WIDTH - 2 * kACCTextStickerBGTextViewLeftMargin + 2 * kACCTextStickeTextViewContainerInset, HUGE)];
    if (self.textModel.widthLimit > 0) {
        textViewSize = [self.textView sizeThatFits:CGSizeMake(self.textModel.widthLimit, HUGE)];
    }
    
    if (textViewSize.width <= 0.0001) {
        textViewSize.width = 20;
    }
    
    // 扩大未输入时候的点击区域，方便用户粘贴
    if (ACC_isEmptyString(self.textView.text)) {
        textViewSize.width = ACC_SCREEN_WIDTH;
    }

    CGFloat selfWidth = textViewSize.width + kACCTextStickerBGColorLeftMargin * 2 - 2 * kACCTextStickeTextViewContainerInset;
    CGFloat selfHeight = textViewSize.height + kACCTextStickerBGColorTopMargin * 2 - 2 * kACCTextStickeTextViewContainerInset;
    self.bounds = CGRectMake(0, 0, selfWidth, selfHeight);
    self.textView.frame = CGRectMake(kACCTextStickerBGColorLeftMargin - kACCTextStickeTextViewContainerInset, kACCTextStickerBGColorTopMargin - kACCTextStickeTextViewContainerInset, textViewSize.width, textViewSize.height);
    if (self.coordinateDidChange) {
        self.coordinateDidChange();
    }
    if (self.enableEdit) {
        [self updateEdtingFrames];
    }
}

- (void)updateEdtingFrames
{
    CGPoint editCenter = CGPointMake(ACC_SCREEN_WIDTH * 0.5, ACC_SCREEN_HEIGHT * 0.27 - 26);
    if (@available(iOS 9.0, *)) {
        editCenter = [[[UIApplication sharedApplication].delegate window] convertPoint:editCenter toView:[self.stickerContainer containerView]];
    }
    
    CGFloat delWhenClickIn = editCenter.y + self.textView.frame.size.height * 0.5 - (ACC_SCREEN_HEIGHT - self.textModel.keyboardHeight - (18 + kACCTextStickerBGColorTopMargin));
    CGPoint editPos = [self.textView caretRectForPosition:self.textView.selectedTextRange.start].origin;
    CGFloat editHight = ACC_SCREEN_HEIGHT - self.textModel.keyboardHeight - (18 + kACCTextStickerBGColorTopMargin);
    
    if (delWhenClickIn > 0) {
        self.minCenterCanBeMoved = CGPointMake(editCenter.x, editCenter.y - 52 - delWhenClickIn).y;
    } else {
        self.minCenterCanBeMoved = CGPointMake(editCenter.x, editCenter.y - 52).y;
    }
    
    if (self.fromClickEdit == YES){ // 若是通过点击进入编辑页则直接定位到输入框尾部
        if (delWhenClickIn > 0) {
            self.center = CGPointMake(editCenter.x, editCenter.y - 52 - delWhenClickIn);
        } else {
            self.center = CGPointMake(editCenter.x, editCenter.y - 52);
        }
        //将标识符定位至文字编辑的尾部
        UITextRange *end = [self.textView textRangeFromPosition:self.textView.endOfDocument toPosition:self.textView.endOfDocument];
        [self.textView setSelectedTextRange:end];
    } else { // 若是输入标识符超出屏幕则自动定位标识符
        if (editPos.y > (-self.acc_origin.y + editHight - 62)) {
            self.acc_origin = CGPointMake(self.acc_origin.x, editHight - 62 - editPos.y);
        }
        if (editPos.y < (-self.acc_origin.y)) {
            self.acc_origin = CGPointMake(self.acc_origin.x, MAX(-editPos.y, 0));
        }
    }
    
    // 超出可拖动范围的兜底
    if (self.frame.origin.y >= 0) {
        self.acc_origin = CGPointMake(self.frame.origin.x, 0);
    }
    
    if (self.center.y < self.minCenterCanBeMoved) {
        if (delWhenClickIn > 0) {
            self.center = CGPointMake(editCenter.x, editCenter.y - 52 - delWhenClickIn);
        } else {
            self.center = CGPointMake(editCenter.x, editCenter.y - 52);
        }
    }
    
    if (self.textModel.alignmentType == AWEStoryTextAlignmentLeft) {
        self.acc_left = kACCTextStickerBGTextViewLeftMargin - kACCTextStickeTextViewContainerInset -  ([self.stickerContainer playerRect].size.width - ACC_SCREEN_WIDTH) * 0.5;
    } else if (self.textModel.alignmentType == AWEStoryTextAlignmentRight) {
        self.acc_right = ACC_SCREEN_WIDTH - kACCTextStickerBGTextViewLeftMargin + kACCTextStickeTextViewContainerInset +  ([self.stickerContainer playerRect].size.width - ACC_SCREEN_WIDTH) * 0.5;
    }
    _editCenter = self.center;
    self.fromClickEdit = NO;
}

#pragma mark - gesture action
// Maybe we should refactor using textview's size and content size scrolling
- (void)panAction:(UIPanGestureRecognizer *)sender
{
    if (self.enableEdit) {
        CGPoint currentPoint = [sender translationInView:self.superview];
        
        if ((self.frame.origin.y + currentPoint.y >= 0) || self.center.y + currentPoint.y < self.minCenterCanBeMoved) {
            self.center = CGPointMake(self.center.x, self.center.y);
        } else {
            self.center = CGPointMake(self.center.x, self.center.y + currentPoint.y);
        }
        
        [sender setTranslation:CGPointZero inView:self.superview];
        return;
    }
}

- (ACCTextStickerTextView *)textView
{
    if (!_textView) {
        NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(self.frame.size.width, CGFLOAT_MAX)];
        textContainer.widthTracksTextView = YES;
        _textView = [[ACCTextStickerTextView alloc] initWithFrame:CGRectZero textContainer:textContainer];
        _textView.autocorrectionType = UITextAutocorrectionTypeDefault;
        _textView.spellCheckingType = UITextSpellCheckingTypeNo;
        // 设计师要求强制为dark
        _textView.keyboardAppearance = UIKeyboardAppearanceDark;
        _textView.tintColor = ACCResourceColor(ACCColorPrimary);
        _textView.acc_delegate = self;
        _textView.font = [ACCFont() systemFontOfSize:self.defaultFontSize weight:ACCFontWeightHeavy];
        _textView.textColor = [UIColor blackColor];
        _textView.scrollEnabled = NO;
        _textView.showsVerticalScrollIndicator = NO;
        _textView.showsHorizontalScrollIndicator = NO;
        _textView.textAlignment = NSTextAlignmentCenter;
        _textView.textContainerInset = UIEdgeInsetsMake(kACCTextStickeTextViewContainerInset, kACCTextStickeTextViewContainerInset, kACCTextStickeTextViewContainerInset, kACCTextStickeTextViewContainerInset);
        _textView.textContainer.lineFragmentPadding = 0;
        _textView.backgroundColor = [UIColor clearColor];
    }
    return _textView;
}

- (void)setTextStickerId:(NSString *)textStickerId
{
    _textStickerId = textStickerId;
    self.textView.textStickerId = textStickerId;
}

- (void)setupSocialBindControllerIfEnableWithinitialExtraInfos:(NSArray<ACCTextStickerExtraModel *> *)extraInfos
{
    if (!self.enableTextStickerSocialBind) {
        return;
    }
    ACCTextStickerInputController *inputController = [[ACCTextStickerInputController alloc] initWithTextView:self.textView initialExtraInfos:extraInfos];
    inputController.delegate = self;
    _inputController = inputController;
}

#pragma mark - ACCTextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    ACCBLOCK_INVOKE(self.textChangedBlock, textView.text);
    self.textModel.content = self.textView.text;
    self.textModel.extraInfos = self.inputController.extraInfos;
    [self updateDisplay];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    ACCBLOCK_INVOKE(self.willChangeTextInRangeBlock, text, range);
    
    BOOL ret = YES;
    
    if (self.inputController) {
        ret =  [self.inputController textView:textView shouldChangeTextInRange:range replacementText:text];
    }

    return ret;
}

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    ACCBLOCK_INVOKE(self.textSelectedChangeBlock, textView.selectedRange);
    
    [self.inputController textViewDidChangeSelection:textView];
}

#pragma mar - ACCTextStickerInputControllerDelegate
- (void)textStickerInputController:(ACCTextStickerInputController *)controller
             didUpdateSearchStatus:(BOOL)shouldSearch
                           Keyword:(NSString *)keyword
                        searchType:(ACCTextStickerExtraType)searchType
{
    ACCBLOCK_INVOKE(self.searchKeyworkChangedBlock, shouldSearch, searchType, keyword);
    
}

- (void)textStickerInputController:(ACCTextStickerInputController *)controller onExtraInfoDidChanged:(NSArray<ACCTextStickerExtraModel *> *)currentExtraInfo
{
    self.textModel.extraInfos = currentExtraInfo;
    [self updateDisplay];
}

- (void)textStickerInputController:(ACCTextStickerInputController *)controller onReplaceText:(NSString *)text withRange:(NSRange)range
{
    [self textViewDidChange:self.textView];
}

#pragma mark - help

- (void)resetTextViewAlignment
{
    if (self.textModel.alignmentType == AWEStoryTextAlignmentLeft) {
        _textView.textAlignment = NSTextAlignmentLeft;
    } else if (self.textModel.alignmentType == AWEStoryTextAlignmentRight) {
        _textView.textAlignment = NSTextAlignmentRight;
    } else {
        _textView.textAlignment = NSTextAlignmentCenter;
    }
}

#pragma mark - Update Text Display

- (void)updateDisplay
{
    if (self.textModel.fontModel) {
        CGFloat fontSize = (self.textModel.fontModel.defaultFontSize > 0) ? self.textModel.fontModel.defaultFontSize : self.defaultFontSize;
        UIFont *font = [ACCCustomFont() fontWithModel:self.textModel.fontModel size:fontSize];
        self.textView.font = font;
    } else {
        self.textView.font = [ACCFont() systemFontOfSize:self.defaultFontSize weight:ACCFontWeightHeavy];
    }
    AWEStoryColor *colorModel = self.textModel.fontColor;
    if (colorModel == nil && self.textModel.colorIndex != nil) {
        colorModel = [[AWEStoryColorChooseView storyColors] acc_objectAtIndex:[self.textModel.colorIndex item]];
    }
    if (colorModel == nil) {
        colorModel = [AWEStoryColorChooseView storyColors].firstObject;
    }
    UIColor *fillColor = nil;
    if (self.textModel.fontModel.hasShadeColor) {
        NSShadow *shadow = [[NSShadow alloc] init];
        shadow.shadowBlurRadius = 10;
        shadow.shadowColor = colorModel.color;
        shadow.shadowOffset = CGSizeMake(0, 0);
        
        NSDictionary *params = @{
            NSShadowAttributeName : shadow,
            NSForegroundColorAttributeName : [UIColor whiteColor],
            NSFontAttributeName : self.textView.font,
            NSBaselineOffsetAttributeName: @(-1.5f),
        };
        [self.textView.textStorage setAttributes:params range:NSMakeRange(0, self.textView.text.length)];
        fillColor = [UIColor clearColor];
    } else {
        if (!self.textModel.fontModel.hasBgColor || self.textModel.textStyle == AWEStoryTextStyleNo || self.textModel.textStyle == AWEStoryTextStyleStroke) {
            self.textView.textColor = colorModel.color;
            fillColor = [UIColor clearColor];
        } else {
            if (CGColorEqualToColor(colorModel.color.CGColor, [ACCUIColorFromRGBA(0xffffff, 1.0) CGColor])) {
                if (self.textModel.textStyle == AWEStoryTextStyleBackground) {
                    self.textView.textColor = [UIColor blackColor];
                } else {
                    self.textView.textColor = [UIColor whiteColor];
                }
            } else {
                self.textView.textColor = [UIColor whiteColor];
            }
            
            if (self.textModel.textStyle == AWEStoryTextStyleBackground) {
                fillColor = colorModel.color;
            } else {
                fillColor = [colorModel.color colorWithAlphaComponent:0.5];
            }
        }
        NSDictionary *params = @{
            NSForegroundColorAttributeName : self.textView.textColor ?: [UIColor whiteColor],
            NSFontAttributeName : self.textView.font,
            NSBaselineOffsetAttributeName: @(-1.5f),
        };
        if (self.textModel.textStyle == AWEStoryTextStyleNo) {
            self.textView.layer.shadowOpacity = 0.15;
        } else {
            self.textView.layer.shadowOpacity = 0.f;
        }
        [self.textView.textStorage setAttributes:params range:NSMakeRange(0, self.textView.text.length)];
    }
    if ((!self.textModel.fontModel || self.textModel.fontModel.supportStroke) && self.textModel.textStyle == AWEStoryTextStyleStroke && colorModel.borderColor) {
        self.textView.acc_layoutManager.strokeConfig = [ACCEditPageStrokeConfig strokeWithWidth:2 color:colorModel.borderColor lineJoin:kCGLineJoinRound];
    } else {
        self.textView.acc_layoutManager.strokeConfig = nil;
    }
    
    [self resetTextViewAlignment];
    
    [self updateFrame];
    
    [self.textView drawBackgroundWithFillColor:fillColor];
}

#pragma mark -

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (self.enableEdit) {
        return [super hitTest:point withEvent:event];
    }
    return nil;
}

@synthesize coordinateDidChange;
@synthesize stickerContainer = _stickerContainer;

- (id)copyForContext:(id)contextId
{
    AWEStoryTextImageModel *textModelCopy = [self.textModel copy];
    ACCTextStickerView *viewCopy = [[ACCTextStickerView alloc] initWithTextInfo:textModelCopy options:self.viewOptions];
    return viewCopy;
}

- (void)updateWithInstance:(id)instance context:(id)contextId
{
    
}

#pragma mark - transport

- (void)transportToEditWithSuperView:(UIView *)superView animation:(void (^)(void))animationBlock animationDuration:(CGFloat)duration;
{
    self.enableEdit = YES;
    self.fromClickEdit = YES;

    CGPoint center = [self.superview convertPoint:self.center toView:superView];
    CGAffineTransform transform = self.superview.transform; // Unreasonably design, refactor in the future
    [self removeFromSuperview];
    [superView addSubview:self];
    self.center = center;
    self.transform = transform;
    [self.textView becomeFirstResponder];

    [UIView animateWithDuration:duration animations:^{
        self.transform = CGAffineTransformIdentity;
        [self updateFrame];
        if (animationBlock) {
            animationBlock();
        }
    } completion:^(BOOL finished) {
        
    }];
}

- (void)restoreToSuperView:(UIView *)superView animationDuration:(CGFloat)duration animationBlock:(void (^)(void))animationBlock completion:(void (^)(void))completion
{
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
        [self updateDisplay];
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];
}

- (void)updateBubbleStatusAfterEdit
{
    if (ACCConfigEnum(kConfigInt_text_reader_multiple_sound_effects, ACCTextReaderPhase2Type) == ACCTextReaderPhase2TypeDisable) {
        NSString *readTitle = self.textModel.readModel.useTextRead ? ACCLocalizedString(@"creation_edit_text_reading_entrance_cancel", @"Remove") : ACCLocalizedString(@"creation_edit_text_reading_entrance", @"Text-to-speech");
        UIView<ACCStickerBubbleEditProtocol> *sticker = (UIView<ACCStickerBubbleEditProtocol> *)[self.stickerContainer stickerViewWithContentView:self];
        if ([sticker conformsToProtocol:@protocol(ACCStickerBubbleEditProtocol)]) {
            [sticker updateBubbleWithTag:@"text_read" title:readTitle image:nil];
        }
    } else {
        NSString *readTitle = ACCLocalizedString(@"creation_edit_text_reading_entrance", @"Text-to-speech");
        UIView<ACCStickerBubbleEditProtocol> *sticker = (UIView<ACCStickerBubbleEditProtocol> *)[self.stickerContainer stickerViewWithContentView:self];
        if ([sticker conformsToProtocol:@protocol(ACCStickerBubbleEditProtocol)]) {
            [sticker updateBubbleWithTag:@"text_read" title:readTitle image:nil];
        }
    }
}
#pragma mark - Content Protocol

- (void)contentDidUpdateToScale:(CGFloat)scale
{
    scale = MAX(1, scale);
    _currentScale = scale;
    CGFloat contentScaleFactor = MIN(3, scale) * [UIScreen mainScreen].scale;

    self.textView.contentScaleFactor = contentScaleFactor;
    [ACCStickerUtils applyScale:contentScaleFactor toLayer:self.textView.layer];
}

#pragma mark - ACCStickerEditContentProtocol
- (void)setTransparent:(BOOL)transparent
{
    _transparent = transparent;
    
    self.alpha = transparent? 0.5: 1.0;
}

@end
