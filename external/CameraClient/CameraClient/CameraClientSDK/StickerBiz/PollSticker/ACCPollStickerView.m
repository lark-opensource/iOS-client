//
//  ACCPollStickerView.m
//  CameraClient-Pods-DouYin
//
//  Created by guochenxiang on 2020/9/7.
//

#import "ACCPollStickerView.h"
#import <CreationKitArch/ACCCustomFontProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCFontProtocol.h>
#import "AWEPollStickerView.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CameraClient/AWEInteractionStickerModel+DAddition.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKitSticker/ACCStickerUtils.h>

@interface ACCPollStickerView () <UITextViewDelegate>

//在编辑页的状态
@property (nonatomic, assign) CGAffineTransform lastTransForm;
@property (nonatomic, assign) CGPoint lastAnchorPoint;

@property (nonatomic, assign) BOOL enableEdit;
@property (nonatomic, assign) CGFloat currentScale;

//写文字时的center
@property (nonatomic, assign) CGPoint editCenter;

@property (nonatomic, assign) BOOL isFirstAppear;

@property (nonatomic, strong) AWEStoryFontModel *selectFont;

@end

@implementation ACCPollStickerView

#pragma mark - ACCStickerContentProtocol

@synthesize coordinateDidChange;
@synthesize stickerContainer;
@synthesize transparent = _transparent;
@synthesize stickerId = _stickerId;
@synthesize triggerDragDeleteCallback = _triggerDragDeleteCallback;

- (id)copyForContext:(id)contextId
{
    AWEInteractionStickerModel *modelCopy = [self.model copy];
    ACCPollStickerView *viewCopy = [[ACCPollStickerView alloc] initWithStickerModel:modelCopy];
    viewCopy.effectIdentifier = self.effectIdentifier;
    return viewCopy;
}

- (void)updateWithInstance:(id)instance context:(id)contextId
{
    
}

- (void)updateWithModel:(AWEInteractionStickerModel *)model
{
    _model = model;
    _effectIdentifier = model.voteID;
}

- (instancetype)initWithStickerModel:(AWEInteractionStickerModel *)model
{
    self = [super init];
    if (self) {
        _model = model;
        
        NSDictionary *attr = @{@"poll_sticker_id":model.voteID?:@""};
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:attr options:kNilOptions error:&error];
        if (error) {
            AWELogToolError(AWELogToolTagEdit, @"[initWithStickerModel] -- error:%@", error);
        }
        NSString *attrStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        self.model.attr = attrStr;
        self.effectIdentifier = model.voteID;
        
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    self.backgroundColor = [UIColor clearColor];
    self.currentScale = 1.f;
    self.isFirstAppear = YES;
    self.lastAnchorPoint = CGPointMake(0.5, 0.5);
    self.lastTransForm = CGAffineTransformIdentity;
    [self addSubview:self.stickerView];
    self.frame = CGRectMake(0, 0, kAWEPollStickerWitdth + 12, 170);
    
    self.stickerView.questionView.text = self.model.voteInfo.question;
    [self.model.voteInfo.options enumerateObjectsUsingBlock:^(AWEInteractionVoteStickerOptionsModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == 0) {
            self.stickerView.option1View.text = obj.optionText;
        } else {
            self.stickerView.option2View.text = obj.optionText;
        }
    }];

    if ([ACCCustomFont().stickerFonts count]) {
        NSString *fontTitle = @"现代";
        [ACCCustomFont().stickerFonts enumerateObjectsUsingBlock:^(AWEStoryFontModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.download && ([obj.title isEqualToString:fontTitle] || [obj.title isEqualToString:@"Modern"])) {
                self.selectFont = obj;
            }
        }];
    }
    [self refreshFont];
    
    if (![self.stickerView.questionView.text length]) {
        [self.stickerView displayQuestionPlaceHolder:NO];
        [self.stickerView updateQuestionConstraintsWhenHide:YES];
        [self.stickerView layoutIfNeeded];//用了autolayout需要立马拿到frame
        [self p_updateFrameWhenQuestionEmpty];
    } else {
        [self.stickerView updateQuestionConstraints];
        [self.stickerView layoutIfNeeded];//用了autolayout需要立马拿到frame
        [self p_updateFrame];
    }
    [self.stickerView updateOptionsConstraints];

    // 适配消费端展示
    if (self.model.voteInfo.style != ACCPollStickerViewStyleEdit) {
        AWEInteractionVoteStickerInfoModel *voteInfo = self.model.voteInfo;
        [self.stickerView showDisplayMode:YES];
        if (voteInfo.options.count > 0) {
            [self.stickerView.option1DisplayView configWithOption:voteInfo.options.firstObject voteInfo:voteInfo];
        }
        if (voteInfo.options.count > 1) {
            [self.stickerView.option2DisplayView configWithOption:[voteInfo.options acc_objectAtIndex:1] voteInfo:voteInfo];
        }
    }
}

- (void)setFrame:(CGRect)frame
{
    frame.size.width = self.stickerView.acc_width + 2 * self.stickerView.acc_left;
    frame.size.height = self.stickerView.acc_height + 2 * self.stickerView.acc_top;
    [super setFrame:frame];
}

- (void)p_updateFrame
{
    self.stickerView.acc_left = 6.f;//实际是 6+(210-197)/2 = 12.5
    self.stickerView.acc_top = 12.f;
    self.stickerView.acc_width = kAWEPollStickerWitdth;
    if (![self.stickerView.questionView.text length]) {
        self.stickerView.questionView.acc_height = kAWEPollStickerQuestionDefaultHeight;
    }
    
    if (self.stickerView.questionView.acc_height <= kAWEPollStickerQuestionDefaultHeight) {
        self.stickerView.acc_height = self.stickerView.questionView.acc_height+(88+8+2);
    } else {
        self.stickerView.acc_height = self.stickerView.questionView.acc_height+(88+8+10);
    }
    self.acc_width = self.stickerView.acc_width + 2 * self.stickerView.acc_left;
    self.acc_height = self.stickerView.acc_height + 2 * self.stickerView.acc_top;
    self.center = self.basicCenter;
    self.editCenter = self.center;
}

- (void)p_updateFrameWhenQuestionEmpty
{
    self.stickerView.acc_left = 6.f;//实际是 6+(210-197)/2 = 12.5
    self.stickerView.acc_top = 12.f;
    self.stickerView.acc_width = kAWEPollStickerWitdth;
    self.stickerView.acc_height = self.stickerView.questionView.acc_height + (88 + 8 + 2);
    self.acc_width = self.stickerView.acc_width + 2 * self.stickerView.acc_left;
    self.acc_height = self.stickerView.acc_height + 2 * self.stickerView.acc_top;
}

#pragma mark -

//进入编辑状态
- (void)resetWithSuperView:(UIView *)superView
{
    //是否允许编辑状态下拖动
    self.enableEdit = YES;
    self.lastTransForm = self.superview.transform;
    
    CGFloat moveDuration = 0.01f;
    CGFloat scaleDuration = 0.f;//must be 0.f
    if (self.isFirstAppear) {
        self.isFirstAppear = NO;
        if (!CGPointEqualToPoint(self.lastCenter,self.superview.center)) {//草稿箱恢复第一次点击编辑
            self.lastCenter = self.superview.center;
        }
        
        if (self.isDraftRecover) {//草稿箱恢复第一次编辑不要放大动画
            self.isDraftRecover = NO;
            moveDuration = 0.3f;
        } else {
            scaleDuration = 0.3f;
            self.hidden = YES;
        }
    } else {
        self.lastCenter = self.superview.center;
        moveDuration = 0.3f;
    }
    
    self.lastAnchorPoint = self.superview.layer.anchorPoint;
    if (![self.stickerView.questionView.text length]) {
        [self.stickerView displayShadowLayer:NO];
    }

    //把textView从全屏的containerview上移动到有上边距的topmaskview上
    if (self.superview) {
        CGPoint centerInContainer = self.superview.center;
        CGPoint centerInMaskTop = [superView convertPoint:centerInContainer fromView:self.superview.superview];
        CGRect originFrame = self.superview.frame;
        [self removeFromSuperview];
        [superView addSubview:self];
        self.frame = originFrame;
        self.transform = self.lastTransForm;
        self.center = centerInMaskTop;
    } else {
        [superView addSubview:self];
        [self p_updateFrame];
    }
    
    [UIView animateWithDuration:moveDuration animations:^{
        self.layer.anchorPoint = CGPointMake(0.5, 0.5);
        self.transform = CGAffineTransformIdentity;
        self.center = self.basicCenter;
    } completion:^(BOOL finished) {
        if (scaleDuration) {
            self.hidden = NO;
            self.layer.anchorPoint = CGPointMake(0.5, 0.5);
            self.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
            self.layer.anchorPoint = CGPointMake(0.5, 0.5);
            [UIView animateWithDuration:scaleDuration animations:^{
                self.transform = CGAffineTransformMakeScale(1.f, 1.f);
            } completion:^(BOOL finished) {
                self.layer.anchorPoint = CGPointMake(0.5, 0.5);
                self.transform = CGAffineTransformIdentity;
                [self.stickerView displayShadowLayer:YES];
            }];
        } else {
            [self.stickerView displayShadowLayer:YES];
        }
    }];
    
    if (![self.stickerView.questionView.text length]) {
        [self.stickerView displayQuestionPlaceHolder:YES];
        [self refreshFont];
        
        [self.stickerView updateQuestionConstraintsWhenHide:NO];
        //为了解决layer和view移动速度不一致的问题
        [self.stickerView displayShadowLayer:NO];
        [UIView animateWithDuration:moveDuration animations:^{
            [self.stickerView layoutIfNeeded];//用了autolayout需要立马拿到frame
        } completion:^(BOOL finished) {
            [self.stickerView displayShadowLayer:YES];
            [self p_updateFrameWhenQuestionEmpty];
        }];
    } else {
        [self.stickerView updateQuestionConstraints];
    }
    
    if (self.stickerView.currentEditType == AWEPollStickerEditTypeOPT1) {
        [self.stickerView.option1View becomeFirstResponder];
    } else if (self.stickerView.currentEditType == AWEPollStickerEditTypeOPT2) {
        [self.stickerView.option2View becomeFirstResponder];
    } else {
        [self.stickerView.questionView becomeFirstResponder];
    }
}

- (void)transToRecordPosWithSuperView:(UIView *)superView
                    animationDuration:(CGFloat)duration
                           completion:(void (^)(void))completion
{
    self.enableEdit = NO;
    //把textView从有上边距的topmaskview上移动到全屏的containerview上
    if (self.superview) {
        CGPoint centerInMaskTop = self.center;
        CGPoint centerInContainer = [superView.superview convertPoint:centerInMaskTop fromView:self.superview];
        self.superview.hidden = YES;
        [self removeFromSuperview];
        [superView addSubview:self];
        superView.hidden = NO;
        self.frame = CGRectMake(0, 0, self.acc_width, self.acc_height);
        self.superview.transform = self.transform;
        self.superview.center = centerInContainer;
    } else {
        [superView addSubview:self];
    }
    
    if (![self.stickerView.questionView.text length]) {
        //为了解决layer和view移动速度不一致的问题
        [self.stickerView displayShadowLayer:NO];
        [self.stickerView updateQuestionConstraintsWhenHide:YES];
        [self.stickerView layoutIfNeeded];//用了autolayout需要立马拿到frame
        [self p_updateFrameWhenQuestionEmpty];
    }
    self.superview.acc_size = self.acc_size;
    
    [self contentDidUpdateToScale:self.currentScale];
    [UIView animateWithDuration:duration animations:^{
        self.superview.layer.anchorPoint = self.lastAnchorPoint;
        self.superview.center = self.lastCenter;
        self.superview.transform = self.lastTransForm;
    } completion:^(BOOL finished) {
        [self.stickerView displayShadowLayer:YES];
        if (completion) {
            completion();
        }
    }];
}

//恢复到拖动状态
- (void)transToRecordPosWithSuperView:(UIView *)superView
                           completion:(void (^)(void))completion
{
    [self transToRecordPosWithSuperView:superView animationDuration:0.3 completion:completion];
}

- (void)updateEditTypeWithTap:(UITapGestureRecognizer *)gesture
{
    CGPoint point = [gesture locationInView:self];
    CGRect stickerFrame = self.stickerView.frame;
    CGRect op1SuperFrame = self.stickerView.option1BGView.frame;
    CGRect op2SuperFrame = self.stickerView.option2BGView.frame;
    
    CGRect option1Frame = op1SuperFrame;
    option1Frame = CGRectInset(CGRectMake(option1Frame.origin.x + stickerFrame.origin.x, option1Frame.origin.y + stickerFrame.origin.y, option1Frame.size.width, option1Frame.size.height), 0, 0);
    if (CGRectContainsPoint(option1Frame, point)) {
        self.stickerView.currentEditType = AWEPollStickerEditTypeOPT1;
    }
    
    CGRect option2Frame = op2SuperFrame;
    option2Frame = CGRectInset(CGRectMake(option2Frame.origin.x + stickerFrame.origin.x, option2Frame.origin.y + stickerFrame.origin.y, option2Frame.size.width, option2Frame.size.height), 0, 0);
    if (CGRectContainsPoint(option2Frame, point)) {
        self.stickerView.currentEditType = AWEPollStickerEditTypeOPT2;
    }
}
#pragma mark - ACCStickerContentProtocol

- (void)contentDidUpdateToScale:(CGFloat)scale
{
    scale = MAX(1, scale);
    _currentScale = scale;
    CGFloat contentScaleFactor = MIN(3, scale) * [UIScreen mainScreen].scale;
    self.stickerView.questionView.contentScaleFactor = contentScaleFactor;
    self.stickerView.option1View.contentScaleFactor = contentScaleFactor;
    self.stickerView.option2View.contentScaleFactor = contentScaleFactor;
    [ACCStickerUtils applyScale:contentScaleFactor toLayer:self.stickerView.questionView.layer];
    [ACCStickerUtils applyScale:contentScaleFactor toLayer:self.stickerView.option1View.layer];
    [ACCStickerUtils applyScale:contentScaleFactor toLayer:self.stickerView.option2View.layer];
}

#pragma mark - getter

- (AWEPollStickerView *)stickerView
{
    if (!_stickerView) {
        _stickerView = [[AWEPollStickerView alloc] initWithFrame:CGRectMake(0, 0, kAWEPollStickerWitdth, 150)];
        _stickerView.questionView.delegate = self;
    }
    return _stickerView;
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    if (textView == self.stickerView.questionView) {
        self.stickerView.currentEditType = AWEPollStickerEditTypeQuestion;
        if (![self.stickerView.questionView.text length]) {
            [self.stickerView displayQuestionPlaceHolder:YES];
        }
        [self.stickerView updateQuestionConstraints];
        [self.stickerView layoutIfNeeded];
        [self refreshFont];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (textView == self.stickerView.questionView) {
        if (textView.returnKeyType == UIReturnKeyDone && [text isEqualToString:@"\n"]){//end edit question and start edit option
            self.stickerView.currentEditType = AWEPollStickerEditTypeOPT1;
            [self.stickerView.option1View becomeFirstResponder];
            return NO;
        }
        
        NSString *newText = [textView.text stringByReplacingCharactersInRange:range withString:text];
        CGFloat textWidth = CGRectGetWidth(UIEdgeInsetsInsetRect(textView.frame, textView.textContainerInset));
        textWidth -= 2.0 * textView.textContainer.lineFragmentPadding;
        CGSize boundingRect = [self sizeOfString:newText constrainedToWidth:textWidth font:textView.font];
        NSInteger numberOfLines = boundingRect.height / textView.font.lineHeight;
        if (numberOfLines <= 3) {
            return YES;
        } else {//fix ios8 backspace bug https://stackoverflow.com/questions/1977934/detect-backspace-in-empty-uitextfield
            if ([text length] == 0 && range.length > 0) {
                return YES;
            } else {
                return NO;
            }
        }
    }
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if (textView == self.stickerView.questionView) {
        if (![self.stickerView.questionView.text length]) {
            [self.stickerView displayQuestionPlaceHolder:YES];
            [self refreshFont];
        }
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (textView == self.stickerView.questionView) {
        if (![self.stickerView.questionView.text length]) {
            [self.stickerView displayQuestionPlaceHolder:YES];
            [self refreshFont];
        } else  {
            [self.stickerView displayQuestionPlaceHolder:NO];
        }
        self.model.voteInfo.question = textView.text ? : @"";
    }
}

#pragma mark - help

-(CGSize)sizeOfString:(NSString *)string constrainedToWidth:(double)width font:(UIFont *)font
{
    return  [string boundingRectWithSize:CGSizeMake(width, DBL_MAX)
                                 options:NSStringDrawingUsesLineFragmentOrigin
                              attributes:@{NSFontAttributeName:font}
                                 context:nil].size;
}

- (void)setSelectFont:(AWEStoryFontModel *)selectFont
{
    _selectFont = selectFont;
    UIFont *defaultFont = [ACCFont() systemFontOfSize:20 weight:ACCFontWeightHeavy];
    if (!selectFont) {
        _stickerView.questionView.font = defaultFont;
        return;
    } else {
        CGFloat fontSize = (selectFont.defaultFontSize>0) ? selectFont.defaultFontSize : 20;
        
        _stickerView.questionView.font = [ACCCustomFont() fontWithModel:selectFont size:fontSize];
    }
    [_stickerView refreshPlaceHolderWidth];
    
    [self refreshFont];
}

- (void)doAfterChange
{
    [self p_updateFrame];
}

- (void)refreshFont
{
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowBlurRadius = 5;
    shadow.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.24];
    shadow.shadowOffset = CGSizeMake(0, 1);
    
    NSDictionary *params = @{NSShadowAttributeName : shadow,
                             NSForegroundColorAttributeName : [UIColor whiteColor],
                             NSFontAttributeName : self.stickerView.questionView.font,
                             NSBaselineOffsetAttributeName: @(-0.5f),
                             };
    [self.stickerView.questionView.textStorage setAttributes:params range:NSMakeRange(0, self.stickerView.questionView.text.length)];
    // 防止有selectRange的情况下，切换字体，textAlignment自动切换成居左，导致背景计算异常的问题
    [self resetTextViewAlignment];
    [self doAfterChange];
}

- (void)resetTextViewAlignment
{
    if ([self.stickerView.questionView.text length]) {
        self.stickerView.questionView.textAlignment = NSTextAlignmentCenter;
    } else {
        self.stickerView.questionView.textAlignment = NSTextAlignmentLeft;
    }
}

#pragma mark - ACCPollStickerViewProtocol
- (void)selectOption:(AWEInteractionVoteStickerOptionsModel *)option voteInfo:(AWEInteractionVoteStickerInfoModel *)voteInfo completion:(void (^)(void))completion
{
    if (voteInfo.options.count > 0) {
        [self.stickerView.option1DisplayView performSelectionAnimationWithOption:voteInfo.options.firstObject voteInfo:voteInfo completion:^{
            ACCBLOCK_INVOKE(completion);
        }];
    }
    if (voteInfo.options.count > 1) {
        [self.stickerView.option2DisplayView performSelectionAnimationWithOption:[voteInfo.options acc_objectAtIndex:1] voteInfo:voteInfo completion:^{
        }];
    }
}

- (AWEInteractionVoteStickerOptionsModel *)tappedVoteInfoForTappedPoint:(CGPoint)point
{
    CGPoint realPoint = [self convertPoint:point toView:self.stickerView];
    if (CGRectContainsPoint(self.stickerView.option1BGView.frame, realPoint)) {
        return self.stickerView.option1DisplayView.option;
    } else if (CGRectContainsPoint(self.stickerView.option2BGView.frame, realPoint)) {
        return self.stickerView.option2DisplayView.option;
    } else {
        return nil;
    }
}

#pragma mark - hit test

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (self.enableEdit) {//编辑的时候点击切换光标
        CGRect stickerFrame = self.stickerView.frame;

        CGRect questionFrame = self.stickerView.questionView.frame;
        questionFrame = CGRectInset(CGRectMake(questionFrame.origin.x + stickerFrame.origin.x, questionFrame.origin.y + stickerFrame.origin.y, questionFrame.size.width, questionFrame.size.height), 0, 0);
        if (CGRectContainsPoint(questionFrame, point)) {
            return self.stickerView.questionView;
        }
        
        CGRect option1Frame = self.stickerView.option1BGView.frame;
        option1Frame = CGRectInset(CGRectMake(option1Frame.origin.x + stickerFrame.origin.x, option1Frame.origin.y + stickerFrame.origin.y, option1Frame.size.width, option1Frame.size.height), 0, 0);
        if (CGRectContainsPoint(option1Frame, point)) {
            return self.stickerView.option1View;
        }
        
        CGRect option2Frame = self.stickerView.option2BGView.frame;
        option2Frame = CGRectInset(CGRectMake(option2Frame.origin.x + stickerFrame.origin.x, option2Frame.origin.y + stickerFrame.origin.y, option2Frame.size.width, option2Frame.size.height), 0, 0);
        if (CGRectContainsPoint(option2Frame, point)) {
            return self.stickerView.option2View;
        }
        
        return [super hitTest:point withEvent:event];
    }
    
    return nil;
}

- (void)setTransparent:(BOOL)transparent
{
    _transparent = transparent;
    
    self.alpha = transparent? 0.5: 1.0;
}

@end
