//
//  AWEWorksPreviewVideoEditView.m
//  AWEStudio-Pods-Aweme
//
//  Created by Pinka on 2020/3/20.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCWorksPreviewVideoEditView.h"
#import <CreativeKit/ACCLanguageProtocol.h>
#import "ACCButton.h"
#import <CreativeKit/ACCAnimatedButton.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import "ACCCutSameVideoThumbnailCell.h"
#import "ACCThumbnailDataSource.h"
#import <CreativeKit/UIImage+CameraClientResource.h>

#import <Masonry/View+MASAdditions.h>

static CGFloat const kACCWorksPreviewVideoEditViewToolBarHeight = 62.0;
static CGFloat const kACCWorksPreviewVideoEditViewSliderHeight = 180.0;
static CGFloat const kACCWorksPreviewVideoEditViewSliderGap = 48.0;

static CGFloat const kACCWorksPreviewVideoEditViewVideoFrameCellHeight = 56.0;
static CGFloat const kACCWorksPreviewVideoEditViewVideoFrameCellWidth = 48.0;

static CGFloat const kkACCWorksPreviewVideoEditViewVideoFrameCellMaskAlpha = 0.6;

@interface ACCWorksPreviewVideoEditView ()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) AWEVideoRangeSlider *videoRangeSlider;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *bottomInfoLabel;
@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) ACCButton *changeMaterialButton;
@property (nonatomic, strong) UIView *videoCropContainerView;

@property (nonatomic, strong) ACCAnimatedButton *closeButton;
@property (nonatomic, strong) ACCAnimatedButton *okButton;
@property (nonatomic, strong) UIView *toolbarBgView;

@property (nonatomic, strong) UICollectionView *framesCollectionView;

@property (nonatomic, strong) ACCThumbnailDataSource *thumbnailDataSource;

@property (nonatomic, strong) UIView *framesCollectionLeftMaskView;
@property (nonatomic, strong) UIView *framesCollectionRightMaskView;

@end

@implementation ACCWorksPreviewVideoEditView

- (instancetype)initWithFrame:(CGRect)frame type:(ACCWorksPreviewVideoEditViewType)type
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self setupUI];
        self.curType = type;
        self.thumbnailDataSource = [[ACCThumbnailDataSource alloc] init];
    }
    
    return self;
}

- (void)setupUI
{
    self.backgroundColor = ACCResourceColor(ACCColorBGCreation2);
    [self addSubview:({
        UIView *view = [[UIView alloc] initWithFrame:self.bounds];
        self.videoCropContainerView = view;
        view.backgroundColor = [UIColor clearColor];
        
        view;
    })];
    
    {
        self.tipsLabel = [[UILabel alloc] init];
        self.tipsLabel.text = ACCLocalizedCurrentString(@"stickpoint_single_video_hint2");
        self.tipsLabel.font = [UIFont systemFontOfSize:10];
        self.tipsLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse3);
        self.tipsLabel.textAlignment = NSTextAlignmentCenter;
        [self.videoCropContainerView addSubview:self.tipsLabel];
        ACCMasMaker(self.tipsLabel, {
            make.centerX.mas_equalTo(self.videoCropContainerView);
            make.top.mas_equalTo(140.0);
        });
    }
    
    [self.videoCropContainerView addSubview:({
        UILabel *label = [[UILabel alloc] init];
        self.titleLabel = label;
        label.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
        label.textColor = ACCResourceColor(ACCColorConstTextInverse);
        label.text = [NSString stringWithFormat:ACCLocalizedString(@"mv_video_second_selected", @"已选取%.1f秒"), 2];
        label;
    })];
    
    [self addSubview:({
        UIView *toolbarBgView = [[UIView alloc] initWithFrame:CGRectZero];
        toolbarBgView.backgroundColor = ACCResourceColor(ACCColorBGCreation2);
        self.toolbarBgView = toolbarBgView;
        
        toolbarBgView;
    })];
    
    [self.videoCropContainerView addSubview:({
        ACCButton *btn = [ACCButton buttonWithSelectedAlpha:0.5];
        self.changeMaterialButton = btn;
        btn.layer.masksToBounds = YES;
        btn.layer.cornerRadius = 2;
        [btn setTitleColor:ACCResourceColor(ACCColorConstTextInverse2) forState:UIControlStateNormal];
        [btn acc_setBackgroundColor:ACCResourceColor(ACCColorConstBGContainer5) forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(onChangeMaterialAction:) forControlEvents:UIControlEventTouchUpInside];

        btn.adjustsImageWhenHighlighted = NO;
        btn.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
        btn.contentEdgeInsets = UIEdgeInsetsMake(0, 12, 0, 12);
        [btn setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [btn setTitle:ACCLocalizedCurrentString(@"mv_items_change") forState:UIControlStateNormal];
        btn;
    })];
    
    [self.videoCropContainerView addSubview:({
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.minimumInteritemSpacing = 0;
        flowLayout.minimumLineSpacing = 0;
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        flowLayout.itemSize = CGSizeMake(kACCWorksPreviewVideoEditViewVideoFrameCellWidth, kACCWorksPreviewVideoEditViewVideoFrameCellHeight);
        
        UICollectionView *framesCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 60.0+2.0, self.bounds.size.width, kACCWorksPreviewVideoEditViewVideoFrameCellHeight) collectionViewLayout:flowLayout];
        if (@available(iOS 10.0, *)) {
            framesCollectionView.prefetchingEnabled = NO;
        }
        framesCollectionView.backgroundColor = [UIColor clearColor];
        framesCollectionView.showsHorizontalScrollIndicator = NO;
        framesCollectionView.contentInset = UIEdgeInsetsMake(0, 48, 0, 48);
        framesCollectionView.contentOffset = CGPointMake(-48, 0);
        [framesCollectionView registerClass:[ACCCutSameVideoThumbnailCell class]
                 forCellWithReuseIdentifier:NSStringFromClass([ACCCutSameVideoThumbnailCell class])];
        framesCollectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        framesCollectionView.dataSource = self;
        framesCollectionView.delegate = self;
        self.framesCollectionView = framesCollectionView;
        
        framesCollectionView;
    })];
    
    [self.videoCropContainerView addSubview:({
        AWEVideoRangeSlider *slider = [[AWEVideoRangeSlider alloc] initWithFrame:CGRectMake(0, 60.0, self.bounds.size.width, kACCWorksPreviewVideoEditViewVideoFrameCellHeight+4.0)
                                                                      slideWidth:kACCWorksPreviewVideoEditViewSliderGap
                                                                     cursorWidth:4
                                                                          height:68
                                                                   hasSelectMask:NO];
        slider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//        slider.isAdapitionOptimize = YES;
        [slider showVideoIndicator];
        [slider lockSliderWidth];
        slider.delegate = self.editManager;
        self.videoRangeSlider = slider;
        
        slider;
    })];
    
    [self addSubview:({
        UIImage *img = ACCResourceImage(@"ic_camera_cancel");
        _closeButton = [[ACCAnimatedButton alloc] init];
        _closeButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-10, -10, -10, -10);
        _closeButton.alpha = 1.0;
        [_closeButton setImage:img forState:UIControlStateNormal];
        [_closeButton setImage:img forState:UIControlStateHighlighted];
        [_closeButton addTarget:self action:@selector(onCloseAction:) forControlEvents:UIControlEventTouchUpInside];
        
        _closeButton;
    })];
    
    [self addSubview:({
        UILabel *label = [[UILabel alloc] init];
        self.bottomInfoLabel = label;
        label.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        label.textColor = ACCResourceColor(ACCColorConstTextInverse);
        label;
    })];

    [self addSubview:({
        UIImage *img = ACCResourceImage(@"ic_camera_save");
        _okButton = [[ACCAnimatedButton alloc] init];
        _okButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-10, -10, -10, -10);
        _okButton.alpha = 1.0;
        [_okButton setImage:img forState:UIControlStateNormal];
        [_okButton setImage:img forState:UIControlStateHighlighted];
        [_okButton addTarget:self action:@selector(onOkAction:) forControlEvents:UIControlEventTouchUpInside];

        _okButton;
    })];
    [self.videoCropContainerView addSubview:({
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                self.framesCollectionView.frame.origin.y,
                                                                kACCWorksPreviewVideoEditViewSliderGap-self.videoRangeSlider.leftThumb.visibleWidth,
                                                                kACCWorksPreviewVideoEditViewVideoFrameCellHeight)];
        self.framesCollectionLeftMaskView = view;
        view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:kkACCWorksPreviewVideoEditViewVideoFrameCellMaskAlpha];
        view.userInteractionEnabled = NO;
        
        view;
    })];
    [self.videoCropContainerView addSubview:({
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(self.bounds.size.width - kACCWorksPreviewVideoEditViewSliderGap + self.videoRangeSlider.rightThumb.visibleWidth,
                                                                self.framesCollectionView.frame.origin.y,
                                                                kACCWorksPreviewVideoEditViewSliderGap-self.videoRangeSlider.rightThumb.visibleWidth,
                                                                kACCWorksPreviewVideoEditViewVideoFrameCellHeight)];
        self.framesCollectionRightMaskView = view;
        view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:kkACCWorksPreviewVideoEditViewVideoFrameCellMaskAlpha];
        view.userInteractionEnabled = NO;
        
        view;
    })];

    {
        UIColor *cmpColor = ACCResourceColor(ACCColorBGCreation2);
        CGFloat red, green, blue;
        [cmpColor getRed:&red green:&green blue:&blue alpha:NULL];
        red /= (1.0-kkACCWorksPreviewVideoEditViewVideoFrameCellMaskAlpha);
        green /= (1.0-kkACCWorksPreviewVideoEditViewVideoFrameCellMaskAlpha);
        blue /= (1.0-kkACCWorksPreviewVideoEditViewVideoFrameCellMaskAlpha);
        
        [self.videoCropContainerView
         insertSubview:({
            UIView *view = [[UIView alloc] initWithFrame:self.framesCollectionLeftMaskView.frame];
            view.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
            view.userInteractionEnabled = NO;
            view;
        })
         belowSubview:self.framesCollectionView];
        
         [self.videoCropContainerView
          insertSubview:({
             UIView *view = [[UIView alloc] initWithFrame:self.framesCollectionRightMaskView.frame];
             view.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
             view.userInteractionEnabled = NO;
             view;
         })
          belowSubview:self.framesCollectionView];
    }
    

    ACCMasMaker(self.videoCropContainerView, {
        make.edges.mas_equalTo(0.0);
    });
    ACCMasMaker(self.titleLabel, {
        make.leading.mas_equalTo(16.0);
        make.top.mas_equalTo(self);
        make.height.mas_equalTo(52.0);
        make.trailing.mas_equalTo(self.changeMaterialButton.mas_leading).offset(16.0);
    });
    ACCMasMaker(self.changeMaterialButton, {
        make.centerY.mas_equalTo(self.titleLabel.mas_centerY);
        make.trailing.mas_equalTo(-16.0);
        make.height.mas_equalTo(28);
        make.width.mas_greaterThanOrEqualTo(60);
    });
    ACCMasMaker(self.closeButton, {
        make.size.mas_equalTo(CGSizeMake(26.0, 26.0));
        make.leading.mas_equalTo(21.0);
        make.bottom.mas_equalTo(-(16.0+ACC_IPHONE_X_BOTTOM_OFFSET));
    });
    
    ACCMasMaker(self.bottomInfoLabel, {
        make.centerX.mas_equalTo(self.mas_centerX);
        make.height.mas_equalTo(26.0);
        make.bottom.mas_equalTo(-(16.0+ACC_IPHONE_X_BOTTOM_OFFSET));
    });
    ACCMasMaker(self.okButton, {
        make.size.mas_equalTo(CGSizeMake(26.0, 26.0));
        make.trailing.mas_equalTo(-21.0);
        make.bottom.mas_equalTo(-(16.0+ACC_IPHONE_X_BOTTOM_OFFSET));
    });
    ACCMasMaker(self.toolbarBgView, {
        make.leading.trailing.bottom.mas_equalTo(0.0);
        make.height.mas_equalTo(ACC_IPHONE_X_BOTTOM_OFFSET+kACCWorksPreviewVideoEditViewToolBarHeight);
    });
    UIView *sectionSeparator = [[UIView alloc] init];
    sectionSeparator.backgroundColor = ACCResourceColor(ACCColorConstLineInverse2);

    [self.toolbarBgView addSubview:sectionSeparator];
    ACCMasMaker(sectionSeparator, {
        make.height.mas_equalTo(0.5);
        make.leading.trailing.top.mas_equalTo(0.0);
    });
}

- (void)reset
{
    self.thumbnailDataSource.sourceAsset = self.videoAsset;
    self.thumbnailDataSource.timeRange = [self.videoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject.timeRange;
    CGFloat lineCount = (self.prepareWidth - kACCWorksPreviewVideoEditViewSliderGap*2) / kACCWorksPreviewVideoEditViewVideoFrameCellWidth;
    self.thumbnailDataSource.thumbnailInterval = CMTimeGetSeconds(self.timeRange.duration) / lineCount;
    [self.thumbnailDataSource generateTimeArray];
    
    self.videoRangeSlider.maxGap = CMTimeGetSeconds(self.timeRange.duration);
    
    if (self.videoAsset) {
        [self.framesCollectionView reloadData];
        CGFloat percent = CMTimeGetSeconds(self.timeRange.start) /CMTimeGetSeconds([self.videoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject.timeRange.duration);
        CGFloat scrollWidth = kACCWorksPreviewVideoEditViewVideoFrameCellWidth*self.thumbnailDataSource.allTimes.count;
        [self.framesCollectionView setContentOffset:CGPointMake(percent * scrollWidth - self.framesCollectionView.contentInset.left, 0.0) animated:NO];
    }
}

- (void)updatePlayTime:(CMTime)time
{
    CMTime newTime = time;
    NSTimeInterval position = CMTimeGetSeconds(newTime);
    [self.videoRangeSlider updateVideoIndicatorByPosition:position];
}

- (void)AnimationForShowCropView
{
    self.closeButton.alpha = 0;
    self.okButton.alpha = 0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.closeButton.alpha = 1;
        self.okButton.alpha = 1;
    });
}

- (void)AnimationForHideCropView
{
    self.closeButton.hidden = YES;
    self.okButton.hidden = YES;
    self.framesCollectionView.alpha = 0;
    self.videoRangeSlider.alpha = 0;
    self.tipsLabel.alpha = 0;
}

#pragma mark - Action
- (void)onChangeMaterialAction:(UIButton *)sender
{
    ACCBLOCK_INVOKE(self.changeMaterialCallback);
}

- (void)onOkAction:(UIButton *)sender
{
    ACCBLOCK_INVOKE(self.okCallback);
}

- (void)onCloseAction:(UIButton *)sender;
{
    ACCBLOCK_INVOKE(self.closeCallback);
}

#pragma mark - Setter
- (void)setEditManager:(id<ACCCutSameStyleCropEditManagerProtocol>)editManager
{
    if (_editManager != editManager) {
        _editManager = editManager;
        
        self.videoRangeSlider.delegate = editManager;
        self.titleLabel.text = [NSString stringWithFormat:ACCLocalizedString(@"mv_video_second_selected", @"已选取%.1f秒"), CMTimeGetSeconds(editManager.bridgeFragment.duration)];
    }
}

- (void)setCurType:(ACCWorksPreviewVideoEditViewType)curType
{
    _curType = curType;
    NSString *info = @"";
    if (curType == ACCWorksPreviewVideoEditViewType_Photo) {
        self.videoCropContainerView.hidden = YES;
        info = ACCLocalizedString(@"creation_clips_preview_image_edit", @"图片编辑");
    } else {
        self.videoCropContainerView.hidden = NO;
        info = ACCLocalizedString(@"creation_clips_preview_single_edit", @"单段编辑");
    }
    self.bottomInfoLabel.text = info;
}

- (CGFloat)currentViewHeight
{
    if (self.curType == ACCWorksPreviewVideoEditViewType_Video) {
        return kACCWorksPreviewVideoEditViewSliderHeight+kACCWorksPreviewVideoEditViewToolBarHeight+ACC_IPHONE_X_BOTTOM_OFFSET;
    } else {
        return kACCWorksPreviewVideoEditViewToolBarHeight+ACC_IPHONE_X_BOTTOM_OFFSET;
    }
}


#pragma mark - UICollectionViewDataSource
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ACCCutSameVideoThumbnailCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(ACCCutSameVideoThumbnailCell.class) forIndexPath:indexPath];
    [self.thumbnailDataSource setImageView:cell.thumbnailImageView
                                  viewSize:CGSizeMake(kACCWorksPreviewVideoEditViewVideoFrameCellWidth, kACCWorksPreviewVideoEditViewVideoFrameCellHeight)
                          placeholderImage:nil
                                 withIndex:indexPath.item];
    
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.thumbnailDataSource.allTimes.count;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    ACCBLOCK_INVOKE(self.pauseCallback);
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (decelerate == NO) {
        ACCBLOCK_INVOKE(self.resumeCallback);
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    ACCBLOCK_INVOKE(self.resumeCallback);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat x = scrollView.contentOffset.x + scrollView.contentInset.left;
    
    if (scrollView.contentSize.width > 0.0) {
        CGFloat percent = x / scrollView.contentSize.width;
        ACCBLOCK_INVOKE(self.scrollCallback, percent);
    }
}

@end
