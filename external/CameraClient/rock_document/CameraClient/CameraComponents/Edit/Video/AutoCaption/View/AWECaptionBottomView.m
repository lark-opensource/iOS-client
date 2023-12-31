//
//  AWECaptionBottomView.m
//  Pods
//
//  Created by lixingdong on 2019/8/29.
//

#import "AWECaptionBottomView.h"
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/NSTimer+ACCAdditions.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>

CGFloat AWEAutoCaptionsBottomViewHeigth = 232.0;
CGFloat kAWECaptionBottomTableViewCellHeight = 44.0;
CGFloat kAWECaptionBottomTableViewContentInsetTop = 64.0;
CGFloat kAWECaptionBottomTableViewHighlightOffset = 40.0;

@implementation AWECaptionScrollFlowLayout

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
    //1.计算scrollview最后停留的范围
    CGRect lastRect ;
    lastRect.origin = proposedContentOffset;
    lastRect.size = self.collectionView.frame.size;
    
    lastRect.origin.x = 0;
    lastRect.origin.y = proposedContentOffset.y + kAWECaptionBottomTableViewHighlightOffset;
    lastRect.size = CGSizeMake(ACC_SCREEN_WIDTH, kAWECaptionBottomTableViewCellHeight);

    //2.取出这个范围内的所有属性
    NSArray *array = [self layoutAttributesForElementsInRect:lastRect];
    if (ACC_isEmptyArray(array)) {
        return CGPointMake(0, -kAWECaptionBottomTableViewContentInsetTop + kAWECaptionBottomTableViewCellHeight / 2.0);
    }

    //3.遍历所有的属性
    CGFloat startY = proposedContentOffset.y;
    CGFloat adjustOffsetY = MAXFLOAT;
    
    UICollectionViewLayoutAttributes *attrs = array.firstObject;
    CGFloat attrsY = CGRectGetMinY(attrs.frame);
    CGFloat attrsH = CGRectGetHeight(attrs.frame) ;

    if (startY - attrsY + kAWECaptionBottomTableViewCellHeight < attrsH / 2) {
        adjustOffsetY = -(startY - attrsY + kAWECaptionBottomTableViewHighlightOffset);
    } else {
        adjustOffsetY = attrsH - (startY - attrsY + kAWECaptionBottomTableViewHighlightOffset);
    }

    CGPoint targetPoint = CGPointMake(proposedContentOffset.x, proposedContentOffset.y + adjustOffsetY + kAWECaptionBottomTableViewHighlightOffset + kAWECaptionBottomTableViewCellHeight * 0.5);
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:targetPoint];
    if (self.delegate && [self.delegate respondsToSelector:@selector(collectionViewScrollStopAtIndex:)]) {
        [self.delegate collectionViewScrollStopAtIndex:indexPath.row];
    }
    return CGPointMake(proposedContentOffset.x, proposedContentOffset.y + adjustOffsetY);
}

@end

@interface AWECaptionBottomView()

// BgView
@property (nonatomic, strong, readwrite) UIView *loadingBgView;
@property (nonatomic, strong, readwrite) UIView *retryBgView;
@property (nonatomic, strong, readwrite) UIView *emptyBgView;
@property (nonatomic, strong, readwrite) UIView *captionBgView;
@property (nonatomic, strong, readwrite) UIView *styleBgView;

// LoadingUI
@property (nonatomic, strong) UIView<ACCLoadingViewProtocol> *loadingView;
@property (nonatomic, strong) UIView *loadingViewBgView;
@property (nonatomic, strong) UILabel *loadingTitle;
@property (nonatomic, strong) UILabel *loadingSubtitle1;
@property (nonatomic, strong) UILabel *loadingSubtitle2;
@property (nonatomic, strong, readwrite) UIButton *cancelButton;

// RetryUI
@property (nonatomic, strong) UILabel *retryTitle;
@property (nonatomic, strong, readwrite) UIButton *retryButton;
@property (nonatomic, strong, readwrite) UIButton *quitButton;

// EmptyUI
@property (nonatomic, strong) UILabel *emptyTitle;
@property (nonatomic, strong, readwrite) UIButton *emptyCancelButton;

// CaptionUI
@property (nonatomic, strong, readwrite) UILabel *captionTitle;
@property (nonatomic, strong, readwrite) ACCAnimatedButton *styleButton;
@property (nonatomic, strong, readwrite) ACCAnimatedButton *deleteButton;
@property (nonatomic, strong, readwrite) ACCAnimatedButton *editButton;
@property (nonatomic, strong, readwrite) UIView *separateLine;
@property (nonatomic, strong, readwrite) UICollectionView *captionCollectionView;

// StyleUI
@property (nonatomic, strong, readwrite) AWEStoryToolBar *styleToolBar;
@property (nonatomic, strong, readwrite) UIView *styleSeparateLine;
@property (nonatomic, strong, readwrite) ACCAnimatedButton *styleCancelButton;
@property (nonatomic, strong, readwrite) ACCAnimatedButton *styleSaveButton;

@property (nonatomic, strong) NSTimer *progressTimer;
@property (nonatomic, strong) NSTimer *hintTimer;

@property (nonatomic, strong) CAShapeLayer *maskLayer;

@end

@implementation AWECaptionBottomView

- (void)dealloc
{
    [self.hintTimer invalidate];
    [self.progressTimer invalidate];
    self.hintTimer = nil;
    self.progressTimer = nil;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.currentRow = -1;
        [self setupUI];
    }
    
    return self;
}

- (void)setupUI
{
    [self addSubview:self.loadingBgView];
    [self addSubview:self.retryBgView];
    [self addSubview:self.emptyBgView];
    [self addSubview:self.captionBgView];
    [self addSubview:self.styleBgView];
    
    // LoadingUI
    [self.loadingBgView addSubview:self.loadingViewBgView];
    [self.loadingBgView addSubview:self.loadingTitle];
    [self.loadingBgView addSubview:self.loadingSubtitle1];
    [self.loadingBgView addSubview:self.loadingSubtitle2];
    [self.loadingBgView addSubview:self.cancelButton];
    
    // RetryUI
    [self.retryBgView addSubview:self.retryTitle];
    [self.retryBgView addSubview:self.retryButton];
    [self.retryBgView addSubview:self.quitButton];
    
    // EmptyUI
    [self.emptyBgView addSubview:self.emptyTitle];
    [self.emptyBgView addSubview:self.emptyCancelButton];
    
    // CaptionView
    [self.captionBgView addSubview:self.captionTitle];
    [self.captionBgView addSubview:self.styleButton];
    [self.captionBgView addSubview:self.deleteButton];
    [self.captionBgView addSubview:self.editButton];
    [self.captionBgView addSubview:self.separateLine];
    [self.captionBgView addSubview:self.captionCollectionView];
    
    // StyleUI
    [self.styleBgView addSubview:self.styleToolBar];
    [self.styleBgView addSubview:self.styleSeparateLine];
    [self.styleBgView addSubview:self.styleCancelButton];
    [self.styleBgView addSubview:self.styleSaveButton];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, frame.size.width, frame.size.height)
                                               byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
                                                     cornerRadii:CGSizeMake(12, 12)];
    self.maskLayer.path = path.CGPath;
    self.layer.mask = self.maskLayer;
}

- (void)refreshUIWithType:(AWECaptionBottomViewType)type
{
    switch (type) {
        case AWECaptionBottomViewTypeLoading:
        {
            self.loadingBgView.hidden = NO;
            self.retryBgView.hidden = YES;
            self.emptyBgView.hidden = YES;
            self.captionBgView.hidden = YES;
            self.styleBgView.hidden = YES;
            [self startLoadingAnim];
        }
            break;
            
        case AWECaptionBottomViewTypeRetry:
        {
            self.loadingBgView.hidden = YES;
            self.retryBgView.hidden = NO;
            self.emptyBgView.hidden = YES;
            self.captionBgView.hidden = YES;
            self.styleBgView.hidden = YES;
            [self stopLoadingAnim];
        }
            break;
            
        case AWECaptionBottomViewTypeEmpty:
        {
            self.loadingBgView.hidden = YES;
            self.retryBgView.hidden = YES;
            self.emptyBgView.hidden = NO;
            self.captionBgView.hidden = YES;
            self.styleBgView.hidden = YES;
            [self stopLoadingAnim];
        }
            break;
            
        case AWECaptionBottomViewTypeCaption:
        {
            self.loadingBgView.hidden = YES;
            self.retryBgView.hidden = YES;
            self.emptyBgView.hidden = YES;
            self.captionBgView.hidden = NO;
            self.styleBgView.hidden = YES;
            [self stopLoadingAnim];
        }
            break;
            
        case AWECaptionBottomViewTypeStyle:
        {
            self.loadingBgView.hidden = YES;
            self.retryBgView.hidden = YES;
            self.emptyBgView.hidden = YES;
            self.captionBgView.hidden = YES;
            self.styleBgView.hidden = NO;
        }
            break;
    }
    
    ACCBLOCK_INVOKE(self.refreshUICompletion, type);
    
}

- (void)refreshCellHighlightWithRow:(NSInteger)row
{
    if (self.captionCollectionView.numberOfSections == 0 || row > [self.captionCollectionView numberOfItemsInSection:0]) {
        return;
    }
    
    if (row >= 0) {
        AWECaptionCollectionViewCell *currentCell = (AWECaptionCollectionViewCell *)[self.captionCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
        AWECaptionCollectionViewCell *lastCell = nil;
        if (row == self.currentRow) {
            if (!currentCell || currentCell.textHighlighted) {
                return;
            } else {
                [currentCell configCaptionHighlight:YES];
            }
        } else {
            if (self.currentRow > 0) {
                lastCell = (AWECaptionCollectionViewCell *)[self.captionCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:self.currentRow inSection:0]];
            }
            
            self.currentRow = row;
            [lastCell configCaptionHighlight:NO];
            [currentCell configCaptionHighlight:YES];
        }
    } else {
        [self.captionCollectionView.visibleCells enumerateObjectsUsingBlock:^(__kindof AWECaptionCollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj configCaptionHighlight:NO];
        }];
    }
    
    // 校正，有些cellForItemAtIndexPath返回为nil的情况，有可能出现多个高亮文字
    for (AWECaptionCollectionViewCell *cell in self.captionCollectionView.visibleCells) {
        if (cell.textHighlighted) {
            NSIndexPath *indexPath = [self.captionCollectionView indexPathForCell:cell];
            if (indexPath.row != row) {
                [cell configCaptionHighlight:NO];
            }
        }
    }
}

- (UICollectionView *)createCaptionCollectionView
{
    AWECaptionScrollFlowLayout *layout = [[AWECaptionScrollFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.itemSize = CGSizeMake(ACC_SCREEN_WIDTH, kAWECaptionBottomTableViewCellHeight);
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    self.layout = layout;
    
    UICollectionView *captionCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 52.0, ACC_SCREEN_WIDTH, self.acc_height - 52.0) collectionViewLayout:layout];
    captionCollectionView.backgroundColor = [UIColor clearColor];
    captionCollectionView.showsVerticalScrollIndicator = NO;
    captionCollectionView.showsHorizontalScrollIndicator = NO;
    captionCollectionView.contentInset = UIEdgeInsetsMake(kAWECaptionBottomTableViewContentInsetTop, 0, self.acc_height - 52.0 - kAWECaptionBottomTableViewContentInsetTop - kAWECaptionBottomTableViewCellHeight, 0);
    [captionCollectionView registerClass:[AWECaptionCollectionViewCell class] forCellWithReuseIdentifier:[AWECaptionCollectionViewCell identifier]];
    
    return captionCollectionView;
}

#pragma mark - Caption Animation

- (void)startLoadingSubtitleAnimation
{
    __block int i = 0;
    __block int flag = 0;
    NSArray *hintTextArray = @[
                               ACCLocalizedString(@"auto_caption_tips1", @"现在只支持普通话识别"),
                               ACCLocalizedString(@"auto_caption_tips2", @"清晰的人声可以提高识别准确率"),
                               ACCLocalizedString(@"auto_caption_tips3", @"变声和加速会降低识别准确率"),
                               ];
    [self loadingSubTitleAnimationWithText:[hintTextArray objectAtIndex:i] flag:flag];
    
    @weakify(self);
    self.hintTimer = [NSTimer acc_scheduledTimerWithTimeInterval:2.0 block:^(NSTimer * _Nonnull timer) {
        @strongify(self);
        flag = (i + 1) % 2;
        i = (i + 1) % hintTextArray.count;
        [self loadingSubTitleAnimationWithText:[hintTextArray objectAtIndex:i] flag:flag];
    } repeats:YES];
}

- (void)loadingSubTitleAnimationWithText:(NSString *)text flag:(int)flag
{
    if (flag == 0) {
        self.loadingSubtitle1.text = text;
        [UIView animateWithDuration:0.25 animations:^{
            self.loadingSubtitle1.alpha = 1.0;
            self.loadingSubtitle2.alpha = 0.0;
        }];
    } else {
        self.loadingSubtitle2.text = text;
        [UIView animateWithDuration:0.25 animations:^{
            self.loadingSubtitle1.alpha = 0.0;
            self.loadingSubtitle2.alpha = 1.0;
        }];
    }
}

- (void)startProgressAnimation
{
    [self startProgressAnimationWithProgress:0 interval:0.1];
}

- (void)startProgressAnimationWithProgress:(NSInteger)progress interval:(CGFloat)interval
{
    [self.progressTimer invalidate];
    self.progressTimer = nil;
    
    __block NSInteger i = progress;
    self.loadingTitle.text = [NSString stringWithFormat:ACCLocalizedCurrentString(@"auto_caption_recognize"), i++];
    
    @weakify(self);
    self.progressTimer = [NSTimer acc_scheduledTimerWithTimeInterval:interval block:^(NSTimer * _Nonnull timer) {
        @strongify(self);
        if (i == 61) {
            [self startProgressAnimationWithProgress:i interval:0.2];
            return;
        }
        if (i == 81) {
            [self startProgressAnimationWithProgress:i interval:0.3];
            return;
        }
        if (i < 99) {
            self.loadingTitle.text = [NSString stringWithFormat:ACCLocalizedCurrentString(@"auto_caption_recognize"), i++];
        } else {
            [self.progressTimer invalidate];
            self.progressTimer = nil;
        }
    } repeats:YES];
}

#pragma mark - Loading UI

- (void)startLoadingAnim {
    self.loadingView = [ACCLoading() showLoadingOnView:self.loadingViewBgView];
    
    [self startLoadingSubtitleAnimation];
    [self startProgressAnimation];
}

- (void)stopLoadingAnim {
    [self.loadingView dismiss];
    [self.hintTimer invalidate];
    [self.progressTimer invalidate];
    self.hintTimer = nil;
    self.progressTimer = nil;
}

#pragma mark - Getter

// BgView
- (UIView *)loadingBgView
{
    if (!_loadingBgView) {
        _loadingBgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, AWEAutoCaptionsBottomViewHeigth)];
        _loadingBgView.backgroundColor = [UIColor clearColor];
        _loadingBgView.hidden = YES;
    }
    
    return _loadingBgView;
}

- (UIView *)retryBgView
{
    if (!_retryBgView) {
        _retryBgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, AWEAutoCaptionsBottomViewHeigth)];
        _retryBgView.backgroundColor = [UIColor clearColor];
        _retryBgView.hidden = YES;
    }
    
    return _retryBgView;
}

- (UIView *)emptyBgView
{
    if (!_emptyBgView) {
        _emptyBgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, AWEAutoCaptionsBottomViewHeigth)];
        _emptyBgView.backgroundColor = [UIColor clearColor];
        _emptyBgView.hidden = YES;
    }
    
    return _emptyBgView;
}

- (UIView *)captionBgView
{
    if (!_captionBgView) {
        _captionBgView = [[UIView alloc] initWithFrame:self.bounds];
        _captionBgView.backgroundColor = ACCResourceColor(ACCColorBGCreation2);
        _captionBgView.hidden = YES;
    }
    
    return _captionBgView;
}

- (UIView *)styleBgView
{
    if (!_styleBgView) {
        _styleBgView = [[UIView alloc] initWithFrame:self.bounds];
        _styleBgView.backgroundColor = [UIColor clearColor];
        _styleBgView.hidden = YES;
    }
    
    return _styleBgView;
}

// LoadingUI
- (UIView *)loadingViewBgView
{
    if (!_loadingViewBgView) {
        _loadingViewBgView = [[UIView alloc] initWithFrame:CGRectMake(0, 32, ACC_SCREEN_WIDTH, 52.0)];
        _loadingViewBgView.backgroundColor = [UIColor clearColor];
    }
    
    return _loadingViewBgView;
}

- (UILabel *)loadingTitle
{
    if (!_loadingTitle) {
        _loadingTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 84, ACC_SCREEN_WIDTH, 18)];
        _loadingTitle.textAlignment = NSTextAlignmentCenter;
        _loadingTitle.textColor = ACCResourceColor(ACCColorConstTextInverse2);
        _loadingTitle.font = [ACCFont() acc_systemFontOfSize:15.0 weight:ACCFontWeightSemibold];
    }
    return _loadingTitle;
}

- (UILabel *)loadingSubtitle1
{
    if (!_loadingSubtitle1) {
        _loadingSubtitle1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 110, ACC_SCREEN_WIDTH, 16.0)];
        _loadingSubtitle1.textAlignment = NSTextAlignmentCenter;
        _loadingSubtitle1.textColor = ACCResourceColor(ACCColorConstTextInverse4);
        _loadingSubtitle1.font = [ACCFont() acc_systemFontOfSize:13];
        _loadingSubtitle1.alpha = 0;
    }
    return _loadingSubtitle1;
}

- (UILabel *)loadingSubtitle2
{
    if (!_loadingSubtitle2) {
        _loadingSubtitle2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 110, ACC_SCREEN_WIDTH, 16.0)];
        _loadingSubtitle2.textAlignment = NSTextAlignmentCenter;
        _loadingSubtitle2.textColor = ACCResourceColor(ACCColorConstTextInverse4);
        _loadingSubtitle2.font = [ACCFont() acc_systemFontOfSize:13];
        _loadingSubtitle2.alpha = 0;
    }
    return _loadingSubtitle2;
}

- (UIButton *)cancelButton
{
    if (!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelButton.frame = CGRectMake((ACC_SCREEN_WIDTH - 80) / 2.0, 154, 80, 28);
        _cancelButton.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainerInverse);
        _cancelButton.layer.cornerRadius = 2.0;
        _cancelButton.layer.masksToBounds = YES;
        [_cancelButton setTitle:ACCLocalizedString(@"auto_caption_cancel", @"cancel") forState:UIControlStateNormal];
        [_cancelButton.titleLabel setFont:[ACCFont() acc_systemFontOfSize:14.0 weight:ACCFontWeightMedium]];
        [_cancelButton setTitleColor:ACCResourceColor(ACCColorConstTextInverse4) forState:UIControlStateNormal];
    }
    return _cancelButton;
}

// RetryUI
- (UILabel *)retryTitle
{
    if (!_retryTitle) {
        _retryTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 57.5, ACC_SCREEN_WIDTH, 17.0)];
        _retryTitle.textAlignment = NSTextAlignmentCenter;
        _retryTitle.textColor = ACCResourceColor(ACCColorConstTextInverse4);
        _retryTitle.font = [ACCFont() acc_systemFontOfSize:14];
        _retryTitle.text = ACCLocalizedString(@"auto_caption_failed", @"字幕识别失败，请重试");
    }
    return _retryTitle;
}

- (UIButton *)retryButton
{
    if (!_retryButton) {
        _retryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _retryButton.frame = CGRectMake(72, 90.5, ACC_SCREEN_WIDTH - 72 * 2, 44);
        _retryButton.backgroundColor =ACCResourceColor(ACCUIColorConstBGContainerInverse);
        _retryButton.layer.cornerRadius = 2.0;
        _retryButton.layer.masksToBounds = YES;
        [_retryButton setTitle:ACCLocalizedString(@"auto_caption_retry", @"重试") forState:UIControlStateNormal];
        [_retryButton.titleLabel setFont:[ACCFont() acc_systemFontOfSize:15.0 weight:ACCFontWeightMedium]];
        [_retryButton setTitleColor:ACCResourceColor(ACCColorConstTextInverse2) forState:UIControlStateNormal];
    }
    return _retryButton;
}

- (UIButton *)quitButton
{
    if (!_quitButton) {
        _quitButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _quitButton.frame = CGRectMake(72, 155, ACC_SCREEN_WIDTH - 72 * 2, 20);
        _quitButton.layer.cornerRadius = 2.0;
        _quitButton.layer.masksToBounds = YES;
        [_quitButton setTitle:ACCLocalizedString(@"auto_caption_exit_recognition", @"退出字幕识别") forState:UIControlStateNormal];
        [_quitButton.titleLabel setFont:[ACCFont() acc_systemFontOfSize:14.0 weight:ACCFontWeightMedium]];
        [_quitButton setTitleColor:ACCResourceColor(ACCUIColorPrimary) forState:UIControlStateNormal];
    }
    return _quitButton;
}

// EmptyUI
- (UILabel *)emptyTitle
{
    if (!_emptyTitle) {
        _emptyTitle = [[UILabel alloc] initWithFrame:CGRectMake(50, 53, ACC_SCREEN_WIDTH - 50 * 2, 66.0)];
        _emptyTitle.textAlignment = NSTextAlignmentCenter;
        _emptyTitle.lineBreakMode = NSLineBreakByWordWrapping;
        _emptyTitle.numberOfLines = 0;
        _emptyTitle.textColor = ACCResourceColor(ACCUIColorConstTextInverse4);
        _emptyTitle.font = [ACCFont() acc_systemFontOfSize:14];
        _emptyTitle.text = ACCLocalizedString(@"auto_caption_no_voice_content", @"暂不支持歌词识别和空内容（如纯音乐）识别，请更换视频后再试");
    }
    return _emptyTitle;
}

- (UIButton *)emptyCancelButton
{
    if (!_emptyCancelButton) {
        _emptyCancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _emptyCancelButton.frame = CGRectMake(72, 138, ACC_SCREEN_WIDTH - 72 * 2, 44);
        _emptyCancelButton.backgroundColor =ACCResourceColor(ACCUIColorConstBGContainerInverse);
        _emptyCancelButton.layer.cornerRadius = 2.0;
        _emptyCancelButton.layer.masksToBounds = YES;
        [_emptyCancelButton setTitle:ACCLocalizedString(@"auto_caption_exit_recognition", @"退出字幕识别") forState:UIControlStateNormal];
        [_emptyCancelButton.titleLabel setFont:[ACCFont() acc_systemFontOfSize:15.0 weight:ACCFontWeightMedium]];
        [_emptyCancelButton setTitleColor:ACCResourceColor(ACCUIColorConstTextInverse2) forState:UIControlStateNormal];
    }
    return _emptyCancelButton;
}

// CaptionUI
- (UILabel *)captionTitle
{
    if (!_captionTitle) {
        CGFloat titleHeight = 52.f;
        _captionTitle = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ACC_SCREEN_WIDTH - 110 - 16, titleHeight)];
        _captionTitle.textAlignment = NSTextAlignmentLeft;
        _captionTitle.textColor = ACCResourceColor(ACCColorConstTextInverse2);
        _captionTitle.font = [ACCFont() acc_systemFontOfSize:13 weight:ACCFontWeightMedium];
        _captionTitle.text = ACCLocalizedString(@"auto_caption_title", @"已自动生成字幕");
        _captionTitle.frame = CGRectMake(16,
                                         0,
                                         [_captionTitle sizeThatFits:CGSizeMake(CGFLOAT_MAX, titleHeight)].width,
                                         titleHeight);
    }
    return _captionTitle;
}

- (ACCAnimatedButton *)styleButton
{
    if (!_styleButton) {
        UIImage *img = ACCResourceImage(@"icon_caption_style");
        _styleButton = [[ACCAnimatedButton alloc] initWithFrame:CGRectMake(ACC_SCREEN_WIDTH - 104, 10, 32, 32)];
        _styleButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-10, -10, -10, -10);
        [_styleButton setImage:img forState:UIControlStateNormal];
        [_styleButton setImage:img forState:UIControlStateHighlighted];
        
        _styleButton.isAccessibilityElement = YES;
        _styleButton.accessibilityTraits = UIAccessibilityTraitButton;
        _styleButton.accessibilityLabel = @"样式";
    }
    return _styleButton;
}


- (ACCAnimatedButton *)deleteButton
{
    if (!_deleteButton) {
        UIImage *img = ACCResourceImage(@"icon_caption_delete");
        _deleteButton = [[ACCAnimatedButton alloc] initWithFrame:CGRectMake(ACC_SCREEN_WIDTH - 52, 10, 32, 32)];
        _deleteButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-10, -10, -10, -10);
        [_deleteButton setImage:img forState:UIControlStateNormal];
        [_deleteButton setImage:img forState:UIControlStateHighlighted];
        
        _deleteButton.isAccessibilityElement = YES;
        _deleteButton.accessibilityTraits = UIAccessibilityTraitButton;
        _deleteButton.accessibilityLabel = @"删除";
    }
    return _deleteButton;
}

- (ACCAnimatedButton *)editButton
{
    if (!_editButton) {
        UIImage *img = ACCResourceImage(@"icon_caption_edit");
        _editButton = [[ACCAnimatedButton alloc] initWithFrame:CGRectMake(ACC_SCREEN_WIDTH - 156, 10, 32, 32)];
        _editButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-10, -10, -10, -10);
        [_editButton setImage:img forState:UIControlStateNormal];
        [_editButton setImage:img forState:UIControlStateHighlighted];
        
        _editButton.isAccessibilityElement = YES;
        _editButton.accessibilityTraits = UIAccessibilityTraitButton;
        _editButton.accessibilityLabel = @"编辑";
    }
    return _editButton;
}

- (UIView *)separateLine
{
    if (!_separateLine) {
        _separateLine = [[UIView alloc] initWithFrame:CGRectMake(0, 51.0, ACC_SCREEN_WIDTH, 1.0 / ACC_SCREEN_SCALE)];
        _separateLine.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.08];
    }
    
    return _separateLine;
}

- (UICollectionView *)captionCollectionView
{
    if (!_captionCollectionView) {
        _captionCollectionView = [self createCaptionCollectionView];
    }
    
    return _captionCollectionView;
}

// StyleUI
- (AWEStoryToolBar *)styleToolBar
{
    if (!_styleToolBar) {
        _styleToolBar = [[AWEStoryToolBar alloc] initWithType:AWEStoryToolBarTypeColorAndFontWithOutAlign];
        _styleToolBar.frame = CGRectMake(0, 36, ACC_SCREEN_WIDTH, 112.0);
        [_styleToolBar.leftButton setImage:ACCResourceImage(@"icTextStyle_0") forState:UIControlStateNormal];
        _styleToolBar.leftButton.isAccessibilityElement = YES;
        _styleToolBar.leftButton.accessibilityTraits = UIAccessibilityTraitButton;
        _styleToolBar.leftButton.accessibilityLabel = @"样式";
    }
    
    return _styleToolBar;
}

- (UIView *)styleSeparateLine
{
    if (!_styleSeparateLine) {
        _styleSeparateLine = [[UIView alloc] initWithFrame:CGRectMake(0, 180.0, ACC_SCREEN_WIDTH, 1.0 / ACC_SCREEN_SCALE)];
        _styleSeparateLine.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.08];
    }
    
    return _styleSeparateLine;
}

- (ACCAnimatedButton *)styleCancelButton
{
    if (!_styleCancelButton) {
        UIImage *img = ACCResourceImage(@"ic_camera_cancel");
        _styleCancelButton = [[ACCAnimatedButton alloc] initWithFrame:CGRectMake(16, 194, 24, 24)];
        _styleCancelButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-20, -20, -20, -20);
        [_styleCancelButton setImage:img forState:UIControlStateNormal];
        [_styleCancelButton setImage:img forState:UIControlStateHighlighted];
        
        _styleCancelButton.isAccessibilityElement = YES;
        _styleCancelButton.accessibilityTraits = UIAccessibilityTraitButton;
        _styleCancelButton.accessibilityLabel = @"取消";
    }
    return _styleCancelButton;
}

- (ACCAnimatedButton *)styleSaveButton
{
    if (!_styleSaveButton) {
        UIImage *img = ACCResourceImage(@"ic_camera_save");
        _styleSaveButton = [[ACCAnimatedButton alloc] initWithFrame:CGRectMake(ACC_SCREEN_WIDTH - 40, 194, 24, 24)];
        _styleSaveButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-20, -20, -20, -20);
        [_styleSaveButton setImage:img forState:UIControlStateNormal];
        [_styleSaveButton setImage:img forState:UIControlStateHighlighted];
        
        _styleSaveButton.isAccessibilityElement = YES;
        _styleSaveButton.accessibilityTraits = UIAccessibilityTraitButton;
        _styleSaveButton.accessibilityLabel = @"保存";
    }
    return _styleSaveButton;
}

- (CAShapeLayer *)maskLayer
{
    if (!_maskLayer) {
        _maskLayer = [CAShapeLayer layer];
    }
    return _maskLayer;
}

- (void)setLayoutDelegate:(id<AWECaptionScrollFlowLayoutDelegate>)layoutDelegate
{
    _layoutDelegate = layoutDelegate;
    self.layout.delegate = layoutDelegate;
}

@end
