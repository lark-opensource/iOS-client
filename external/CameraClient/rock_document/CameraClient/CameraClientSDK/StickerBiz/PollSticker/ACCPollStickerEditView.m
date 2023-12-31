//
//  ACCPollStickerEditView.m
//  CameraClient-Pods-Aweme
//
//  Created by aloes on 2020/9/20.
//

#import "ACCPollStickerEditView.h"
#import <CreativeKit/ACCAnimatedButton.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <Masonry/View+MASAdditions.h>
#import "ACCPollStickerView.h"
#import <CameraClient/AWEInteractionStickerModel+DAddition.h>
#import "AWEPollStickerView.h"
#import <CreationKitArch/AWEEditGradientView.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>

CGFloat ACCPollStickerEditViewTopMaskMargin = 52;

@interface ACCPollStickerEditView ()

@property (nonatomic, strong) UIView *textMaskView;
@property (nonatomic, strong) ACCAnimatedButton *finishButton;
@property (nonatomic, strong) UIView *topMaskView;//顶部52pt的范围内部能显示文字，所以在编辑状态下把textView加到topMaskView上。

@property (nonatomic, strong) UIView *originSuperView;

@property (nonatomic, assign) BOOL beginLabelProgress;
@property (nonatomic, assign) BOOL isEditFinished;
@property (nonatomic, assign) BOOL needRecover; //take ScreenShot Recover
@property (nonatomic, assign) CGFloat leftBeyond;

@property (nonatomic, strong) ACCPollStickerView *currentStickerView;
@property (nonatomic, strong, nullable) ACCPollStickerView *currentOperationView;//当前手指拖动的是哪个view
@property (nonatomic, strong) NSMutableArray<ACCPollStickerView *> *stickerViews;

@end

@implementation ACCPollStickerEditView

- (void)dealloc
{
    [self p_removeObservers];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.isEditFinished = YES;
        [self setupUI];
    }
    
    return self;
}

- (void)setupUI
{
    [self addSubview:self.finishButton];
    [self addSubview:self.topMaskView];
    
    CGFloat topBeyond = (self.frame.size.height - ACC_SCREEN_HEIGHT) * 0.5 + ([UIDevice acc_isIPhoneX] ? 22 : 16);
    CGFloat leftBeyond = (self.frame.size.width - ACC_SCREEN_WIDTH) * 0.5;
    self.leftBeyond = leftBeyond;
    
    ACCMasMaker(self.topMaskView, {
        make.top.equalTo(self.mas_top).offset(ACCPollStickerEditViewTopMaskMargin + ACC_NAVIGATION_BAR_OFFSET);
        make.right.left.bottom.equalTo(self);
    });
    
    CGFloat offsetY = topBeyond + ACC_NAVIGATION_BAR_OFFSET;
    CGSize finishButtonSize = [self.finishButton sizeThatFits:CGSizeMake(MAXFLOAT, 32)];
    self.finishButton.acc_width = finishButtonSize.width;
    self.finishButton.acc_height = finishButtonSize.height;
    self.finishButton.acc_left = self.acc_width - (leftBeyond + 12) - finishButtonSize.width;
    self.finishButton.acc_top = self.acc_top + offsetY;
    
    self.finishButton.alpha = 0;
    self.finishButton.hidden = YES;
    [self p_addObservers];
}
    
- (void)startEditStickerView:(ACCPollStickerView *)stickerView
{
    if (self.beginLabelProgress) {
        return;
    }
    self.beginLabelProgress = YES;
    ACCBLOCK_INVOKE(self.startEditBlock);
    
    [self addSubview:self.textMaskView];
    self.finishButton.alpha = 0;
    self.textMaskView.alpha = 0;
    self.finishButton.hidden = NO;
    [UIView animateWithDuration:0.3f animations:^{
        self.finishButton.alpha = 1;
        self.textMaskView.alpha = 1;
    }];
    self.originSuperView = stickerView.superview;
    if (![self.stickerViews containsObject:stickerView]) {
        stickerView.leftBeyond = self.leftBeyond;

        CGPoint lastCenterInScreen = CGPointMake(ACC_SCREEN_WIDTH * 0.5, ACC_SCREEN_HEIGHT * 0.5 - 20);
        CGPoint basicCenterInScreen = CGPointMake(ACC_SCREEN_WIDTH * 0.5, ACC_SCREEN_HEIGHT * 0.25 - 20);
        stickerView.lastCenter = [[[UIApplication sharedApplication].delegate window] convertPoint:lastCenterInScreen toView:self];
        stickerView.basicCenter = [[[UIApplication sharedApplication].delegate window] convertPoint:basicCenterInScreen toView:self];
        [self.stickerViews addObject:stickerView];
    }
    @weakify(self);
    stickerView.stickerView.finishEditBlock = ^{
        @strongify(self);
        [self didFinishEdit];
    };
    self.currentOperationView = stickerView;
    self.currentStickerView = stickerView;
    self.topMaskView.hidden = NO;
    [stickerView resetWithSuperView:self.topMaskView];
    
    [self bringSubviewToFront:self.topMaskView];
    [self bringSubviewToFront:self.finishButton];
    self.isEditFinished = NO;
}

#pragma mark - observers

- (void)p_addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardChangeFrameNoti:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHideNoti:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillShowNoti:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)p_removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)handleKeyboardChangeFrameNoti:(NSNotification *)noti
{
    if (!self.window || !self.superview || !self.beginLabelProgress) {
        return;
    }
    
    NSTimeInterval duration = [[noti.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [[noti.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    CGRect keyboardBounds;
    [[noti.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardBounds];
    
    self.currentStickerView.keyboardHeight = (keyboardBounds.size.height > 0) ? keyboardBounds.size.height : 260;
    [UIView animateWithDuration:duration delay:0 options:(curve<<16) animations:^{
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {}];
}

- (void)handleKeyboardWillHideNoti:(NSNotification *)noti
{
    if (!self.isEditFinished) {
        [self didFinishEdit];
        self.needRecover = YES;
    }
}

- (void)didFinishEdit
{
    self.isEditFinished = YES;
    [self endEditing:YES];
    
    [self setVoteInfoWhenFinish];
    ACCPollStickerView *pollView = self.currentStickerView;

    pollView.stickerView.currentEditType = AWEPollStickerEditTypeNone;
    //set placeholder as default when opttionview text is empty
    pollView.stickerView.option1View.textAlignment = NSTextAlignmentCenter;
    pollView.stickerView.option2View.textAlignment = NSTextAlignmentCenter;

    @weakify(self);
    [pollView transToRecordPosWithSuperView:self.originSuperView completion:^{
        @strongify(self);
        self.currentStickerView = nil;
    }];
    
    self.finishButton.hidden = YES;
    [UIView animateWithDuration:0.2 animations:^{
        self.textMaskView.alpha = 0;
        self.finishButton.alpha = 0;
    } completion:^(BOOL finished) {
        self.beginLabelProgress = NO;
        [self removeFromSuperview];
    }];

    ACCBLOCK_INVOKE(self.finishEditBlock);
}

- (void)setVoteInfoWhenFinish
{
    [self.currentStickerView.stickerView displayQuestionPlaceHolder:NO];
    
    AWEInteractionVoteStickerOptionsModel *option1 = [[AWEInteractionVoteStickerOptionsModel alloc] init];
    AWEInteractionVoteStickerOptionsModel *option2 = [[AWEInteractionVoteStickerOptionsModel alloc] init];
    
    if ([self.currentStickerView.stickerView.option1View.text length]) {
        option1.optionText = self.currentStickerView.stickerView.option1View.text;
    } else {
        option1.optionText = [self.currentStickerView.stickerView.option1View.attributedPlaceholder string];
    }
    
    if ([self.currentStickerView.stickerView.option2View.text length]) {
        option2.optionText = self.currentStickerView.stickerView.option2View.text;
    } else {
        option2.optionText = [self.currentStickerView.stickerView.option2View.attributedPlaceholder string];
    }
    self.currentStickerView.model.voteInfo.options = @[option1,option2];
    
    if (![self.currentStickerView.stickerView.option1View.text length]) {
        self.currentStickerView.stickerView.option1View.text = [self.currentStickerView.stickerView.option1View.attributedPlaceholder string];
    }
    if (![self.currentStickerView.stickerView.option2View.text length]) {
        self.currentStickerView.stickerView.option2View.text = [self.currentStickerView.stickerView.option2View.attributedPlaceholder string];
    }
}

- (void)handleKeyboardWillShowNoti:(NSNotification *)noti
{
    // 截屏恢复
    if (self.currentOperationView && self.needRecover && !self.window && !self.superview) {
        ACCBLOCK_INVOKE(self.takeScreenShotRecover, self.currentOperationView);
        self.needRecover = NO;
    }
}

#pragma mark - action

- (void)didClickedFinish:(UIButton *)button
{
    [self didFinishEdit];
}

- (void)didClickedTextMaskView
{
    [self didFinishEdit];
}

#pragma mark - getter

- (UIView *)topMaskView
{
    if (!_topMaskView) {
        _topMaskView = [[AWEEditGradientView alloc] init];
        _topMaskView.backgroundColor = [UIColor clearColor];
        _topMaskView.clipsToBounds = YES;
    }
    return _topMaskView;
}

- (UIView *)textMaskView
{
    if (_textMaskView == nil) {
        _textMaskView = [[UIView alloc] initWithFrame:self.bounds];
        _textMaskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        [_textMaskView acc_addSingleTapRecognizerWithTarget:self action:@selector(didClickedTextMaskView)];
    }
    return _textMaskView;
}

- (ACCAnimatedButton *)finishButton
{
    if (_finishButton == nil) {
        _finishButton = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeAlpha];
        [_finishButton.titleLabel setFont:[ACCFont() systemFontOfSize:17 weight:ACCFontWeightMedium]];
        [_finishButton setTitle: ACCLocalizedString(@"done", @"完成")  forState:UIControlStateNormal];
        [_finishButton addTarget:self action:@selector(didClickedFinish:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _finishButton;
}

- (NSMutableArray<ACCPollStickerView *> *)stickerViews
{
    if (!_stickerViews) {
        _stickerViews = [@[] mutableCopy];
    }
    return _stickerViews;
}

@end
