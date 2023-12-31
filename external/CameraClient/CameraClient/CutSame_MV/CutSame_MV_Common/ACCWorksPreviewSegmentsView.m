//
//  AWEWorksPreviewSegmentsView.m
//  AWEStudio-Pods-Aweme
//
//  Created by Pinka on 2020/3/15.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCWorksPreviewSegmentsView.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/UIImage+CameraClientResource.h>

#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <Masonry/View+MASAdditions.h>

static CGFloat const kAWEWorksPreviewSegmentsViewMargin = 16.0;
static CGFloat const kAWEWorksPreviewSegmentsViewCellSize = 48.0;
static CGFloat const kAWEWorksPreviewSegmentsViewTitleSectionHeight = 52.0;
static CGFloat const kAWEWorksPreviewSegmentsViewDefaultHeight = 208;

static NSTimeInterval const kAWEWorksPreviewSegmentsViewVideosCollectionInterativeDiff = 3.0;

@interface ACCWorksPreviewSegmentsView ()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UIView *sectionSeparator;

@property (nonatomic, assign) NSTimeInterval lastCollectionViewInteractiveTime;

@property (nonatomic, assign) BOOL textEditEnable;

@end

@implementation ACCWorksPreviewSegmentsView

+ (CGFloat)defaultHeight
{
    return kAWEWorksPreviewSegmentsViewDefaultHeight + ACC_IPHONE_X_BOTTOM_OFFSET;
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame textEditEnable:YES];
}

- (instancetype)initWithFrame:(CGRect)frame textEditEnable:(BOOL)textEditEnable
{
    self = [super initWithFrame:frame];

    if (self) {
        self.textEditEnable = textEditEnable;
        self.panelAnimationDuration = 0.35;
        [self buildViews];
    }

    return self;
}

- (void)buildViews
{
    self.backgroundColor = ACCResourceColor(ACCColorBGCreation2);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, ACC_SCREEN_WIDTH, [ACCWorksPreviewSegmentsView defaultHeight])
                                               byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
                                                     cornerRadii:CGSizeMake(12, 12)];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = [path CGPath];
    self.layer.mask = maskLayer;

    [self addSubview:self.titleLabel];
    [self addSubview:self.sectionSeparator];
    [self addSubview:self.editTextButton];
    [self addSubview:self.videosCollectionView];
    [self.videosCollectionView addSubview:self.cursorView];

    ACCMasMaker(self.titleLabel, {
        make.leading.mas_equalTo(kAWEWorksPreviewSegmentsViewMargin);
        make.top.mas_equalTo(self);
        make.height.mas_equalTo(kAWEWorksPreviewSegmentsViewTitleSectionHeight);
        make.trailing.mas_equalTo(self.editTextButton.mas_leading).offset(kAWEWorksPreviewSegmentsViewMargin);
    });

    ACCMasMaker(self.sectionSeparator, {
        make.height.mas_equalTo(0.5);
        make.leading.trailing.mas_equalTo(0);
        make.top.mas_equalTo(self.editTextButton.mas_bottom).offset(11.5);
    });

    ACCMasMaker(self.editTextButton, {
        make.centerY.mas_equalTo(self.titleLabel.mas_centerY);
        make.trailing.mas_equalTo(-kAWEWorksPreviewSegmentsViewMargin);
        make.height.mas_equalTo(28);
        make.width.mas_greaterThanOrEqualTo(60);
        if (self.textEditEnable == NO) {
            make.width.mas_equalTo(0);
        }
    });
    
    ACCMasMaker(self.videosCollectionView, {
        make.leading.trailing.mas_equalTo(self);
        make.centerY.mas_equalTo(self.mas_centerY);
        make.height.mas_equalTo(kAWEWorksPreviewSegmentsViewCellSize);
    });
}

- (void)updateLastCollectionViewInteractiveTime
{
    self.lastCollectionViewInteractiveTime = [[NSDate date] timeIntervalSince1970];
}

- (BOOL)checkLastCollectionViewInteractiveTimeDiff
{
    return ([[NSDate date] timeIntervalSince1970] > self.lastCollectionViewInteractiveTime+kAWEWorksPreviewSegmentsViewVideosCollectionInterativeDiff);
}

#pragma mark - Public
+ (CGSize)thumbnailPixelSize
{
    return CGSizeMake(ACC_SCREEN_SCALE*kAWEWorksPreviewSegmentsViewCellSize,
                      ACC_SCREEN_SCALE*kAWEWorksPreviewSegmentsViewCellSize);
}

- (void)snapshotForPanelTransitionAnimation:(ACCVideoListCell *)listCell heightDiff:(CGFloat)heightDiff
{
}

- (void)hidePanelWithAnimationWithCoverFrame:(CGRect)targetCoverFrame
{
    self.videosCollectionView.hidden = YES;
    [UIView animateWithDuration:self.panelAnimationDuration animations:^{
        self.titleLabel.alpha = 0;
        self.editTextButton.alpha = 0;
        self.sectionSeparator.alpha = 0;
    } completion:^(BOOL finished) {
        self.alpha = 0;
    }];
}

- (void)showPanelWithAnimationWithCompletion:(dispatch_block_t)completion
{
    self.alpha = 1;

    [UIView animateWithDuration:self.panelAnimationDuration animations:^{
        self.titleLabel.alpha = 1;
        self.editTextButton.alpha = 1;
        self.sectionSeparator.alpha = 1;
    } completion:^(BOOL finished) {
        self.videosCollectionView.hidden = NO;
        ACCBLOCK_INVOKE(completion);
    }];
}

- (void)animateForShowCropViewWithSelectedIndex:(NSUInteger)index isImage:(BOOL)isImage
{
    if (isImage) {
        self.titleLabel.hidden = YES;
        self.editTextButton.hidden = YES;
    }
}

- (void)animateForHideCropView
{
    self.titleLabel.hidden = NO;
    self.editTextButton.hidden = NO;
}

- (void)updateCursorWithIndex:(NSUInteger)index animated:(BOOL)animated
{
    self.cursorView.hidden = NO;
    UICollectionView *collectionView = self.videosCollectionView;

    CGFloat spacing = 16;
    CGSize itemSize = CGSizeMake(kAWEWorksPreviewSegmentsViewCellSize, kAWEWorksPreviewSegmentsViewCellSize);

    CGFloat x = (spacing + itemSize.width) * index + itemSize.width / 2 + spacing;

    CGPoint center = CGPointMake(x, self.cursorView.acc_centerY);

    [UIView animateWithDuration:animated ? 0.15 : 0
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.cursorView.center = center;
    }
                     completion:^(BOOL finished) {
        ;
    }];

    if (collectionView.isTracking || collectionView.isDragging || collectionView.isDecelerating) {
        return;
    }
    
    if (![self checkLastCollectionViewInteractiveTimeDiff]) {
        return ;
    }

    if (self.currentVideoIndex != index) {
        // scroll to visible
        CGRect targetRect = CGRectZero;
        targetRect.size = itemSize;
        targetRect.origin.x = x - targetRect.size.width / 2.0;
        targetRect.origin.y = 0;
        [collectionView scrollRectToVisible:targetRect animated:animated];
    }

    self.currentVideoIndex = index;
}

- (void)hideCursor
{
    self.cursorView.hidden = YES;
}

#pragma mark - Setter & Getter
- (void)setThumbnailImages:(NSArray<UIImage *> *)thumbnailImages
{
    if (_thumbnailImages != thumbnailImages) {
        _thumbnailImages = [thumbnailImages copy];
        
        [self.videosCollectionView reloadData];
    }
}

- (UICollectionView *)videosCollectionView
{
    if (!_videosCollectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.minimumInteritemSpacing = 16;
        flowLayout.minimumLineSpacing = 16;
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        flowLayout.sectionInset = UIEdgeInsetsMake(0, 16.0, 0, 16.0);
        flowLayout.itemSize = CGSizeMake(kAWEWorksPreviewSegmentsViewCellSize, kAWEWorksPreviewSegmentsViewCellSize);

        _videosCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        _videosCollectionView.backgroundColor = [UIColor clearColor];
        _videosCollectionView.alwaysBounceHorizontal = YES;
        _videosCollectionView.showsHorizontalScrollIndicator = NO;
        _videosCollectionView.delegate = self;
        _videosCollectionView.dataSource = self;

        _videosCollectionView.clipsToBounds = NO;
        [_videosCollectionView registerClass:[ACCVideoListCell class]
                  forCellWithReuseIdentifier:NSStringFromClass([ACCVideoListCell class])];

    }

    return _videosCollectionView;
}

- (UIImageView *)cursorView
{
    if (!_cursorView) {
        CGFloat height = 2;
        CGFloat width = 10;
        _cursorView = [[UIImageView alloc] initWithFrame:CGRectMake((kAWEWorksPreviewSegmentsViewCellSize - width) / 2.0, kAWEWorksPreviewSegmentsViewCellSize + (20 - height) / 2, width, height)];
        _cursorView.backgroundColor = ACCResourceColor(ACCColorConstTextInverse);
    }

    return _cursorView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = ACCLocalizedCurrentString(@"mv_items_edit");
        _titleLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
        _titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        _titleLabel.numberOfLines = 2;
    }
    return _titleLabel;
}

- (ACCButton *)editTextButton
{
    if (!_editTextButton) {
        _editTextButton = [ACCButton buttonWithSelectedAlpha:0.5];
        _editTextButton.layer.masksToBounds = YES;

        _editTextButton.layer.cornerRadius = 2;
        [_editTextButton setTitleColor:ACCResourceColor(ACCColorConstTextInverse2) forState:UIControlStateNormal];
        [_editTextButton acc_setBackgroundColor:ACCResourceColor(ACCColorConstBGContainer5) forState:UIControlStateNormal];

        _editTextButton.adjustsImageWhenHighlighted = NO;
        _editTextButton.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        _editTextButton.contentEdgeInsets = UIEdgeInsetsMake(0, 12, 0, 12);
        [_editTextButton setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_editTextButton setImage:ACCResourceImage(@"ic_cut_same_text_editor") forState:UIControlStateNormal];
        [_editTextButton setTitle:ACCLocalizedString(@"creation_mv_text_edit", @"文字编辑") forState:UIControlStateNormal];
        [_editTextButton setImageEdgeInsets:UIEdgeInsetsMake(0, -1.5, 0, 1.5)];
        [_editTextButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 1.5, 0, -1.5)];
        if (self.textEditEnable == NO) {
            _editTextButton.alpha = 0;
        }
    }
    return _editTextButton;
}

- (UIView *)sectionSeparator
{
    if (!_sectionSeparator) {
        _sectionSeparator = [[UIView alloc] init];
        _sectionSeparator.backgroundColor = ACCResourceColor(ACCColorLinePrimary3);
    }
    return _sectionSeparator;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self updateLastCollectionViewInteractiveTime];
}

#pragma mark - ACCCutSameWorksPreviewBottomViewProtocol
- (CGFloat)currentViewHeight
{
    return kAWEWorksPreviewSegmentsViewDefaultHeight + ACC_IPHONE_X_BOTTOM_OFFSET;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ACCBLOCK_INVOKE(self.selectCallback, indexPath.item);
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.thumbnailImages.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ACCVideoListCell *cell = [self.videosCollectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([ACCVideoListCell class])
                                                                                  forIndexPath:indexPath];
    [cell setCoverImage:self.thumbnailImages[indexPath.item] animated:NO];
    if (indexPath.item < self.thumbnailTimes.count) {
        cell.timeLabel.text = [NSString stringWithFormat:@"%.1fs", self.thumbnailTimes[indexPath.item].doubleValue];
        cell.timeLabel.hidden = YES;
    }
    
    return cell;
}

@end
