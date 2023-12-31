//
//  ACCMusicCollectionTableViewCell.m
//  AWEStudio
//
//  Created by 李彦松 on 2018/9/8.
//  Copyright © 2018年 bytedance. All rights reserved.
//


#import "ACCMusicCollectionTableViewCell.h"
#import "AWEMusicCollectionData.h"
#import "ACCMusicCollectionFeedModel.h"
#import "AWESingleMusicCollectionViewCell.h"
#import "ACCVideoMusicCategoryModel.h"
#import "AWESingleMusicView.h"
#import "ACCVideoMusicProtocol.h"
#import "ACCMusicViewBuilderProtocol.h"
#import <CreationKitInfra/ACCConfigManager.h>
#import "ACCConfigKeyDefines.h"
#import "ACCPersonalRecommendWords.h"

#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>

#import <Masonry/View+MASAdditions.h>


static const CGFloat kInitialContentOffsetX = 16;

@interface ACCMusicCollectionTableViewCell ()<UICollectionViewDataSource, UICollectionViewDelegate, AWESingleMusicViewDelegate>

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, strong) UIView<ACCLoadingViewProtocol>* loadingView;
@property (nonatomic, strong) AWEMusicCollectionData *data;
@property (nonatomic, copy)   NSArray<id<ACCMusicModelProtocol>> *musicList;
@property (nonatomic, assign) BOOL useRankIcon;
@property (nonatomic, assign) NSInteger playMusicIndex;
@property (nonatomic, assign) ACCAVPlayerPlayStatus playMusicStatus;
@property (nonatomic, strong) UIView *topLineView;
@property (nonatomic, strong) UICollectionViewFlowLayout *flowlayout;
@property (nonatomic, assign) int currentPage;

@end

@implementation ACCMusicCollectionTableViewCell

@synthesize completion = _completion, enableClipBlock = _enableClipBlock, willClipBlock = _willClipBlock;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _playMusicIndex = NSNotFound;
        [self setupUI];
        self.contentView.isAccessibilityElement = NO;
    }
    return self;
}

- (void)dealloc
{
    [self hideLoading];
}

#pragma mark - Public

- (void)setShowMore:(BOOL)showMore {
    if (_showMore == showMore) {
        return;
    }
    _showMore = showMore;
    [self.musicCollectionView reloadData];
}

- (void)setShowClipButton:(BOOL)showClipButton
{
    if (_showClipButton != showClipButton) {
        _showClipButton = showClipButton;
        [self.musicCollectionView reloadData];
    }
}

- (void)configWithMusicCollectionData:(AWEMusicCollectionData *)data showTopLine:(BOOL)showTopLine {
    self.data = data;
    switch (data.type) {
        case AWEMusicCollectionDataTypeMusicCollection:
        {
            self.musicList = data.collectionFeed.musicList;
            self.useRankIcon = data.collectionFeed.category.isHot;
            self.titleLabel.text = data.collectionFeed.category.name;
        }
            break;
        case AWEMusicCollectionDataTypeMusicArray:
        {
            self.musicList = data.musicList;
            self.useRankIcon = NO;
            self.titleLabel.text = ACCPersonalRecommendGetWords(@"music_search_music_list");
        }
            break;
        default:
            break;
    }
    self.topLineView.hidden = !showTopLine;
    [self.musicCollectionView reloadData];
}

- (void)configWithPlayerStatus:(ACCAVPlayerPlayStatus)playerStatus forRow:(NSInteger)row {
    AWESingleMusicCollectionViewCell *cell =
            (AWESingleMusicCollectionViewCell *)[self.musicCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    if (playerStatus == ACCAVPlayerPlayStatusPause || playerStatus == ACCAVPlayerPlayStatusReachEnd) {
        [cell configWithPlayerStatus:playerStatus];
        self.playMusicStatus = ACCAVPlayerPlayStatusPause;
        self.playMusicIndex = NSNotFound;
    } else if (playerStatus == ACCAVPlayerPlayStatusLoading || playerStatus == ACCAVPlayerPlayStatusPlaying){
        [cell configWithPlayerStatus:playerStatus];
        self.playMusicStatus = playerStatus;
        self.playMusicIndex = row;
    }
}

- (CGFloat)initialContentOffsetX
{
    return kInitialContentOffsetX;
}

#pragma mark - Protocols
#pragma mark UIScrollView

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    CGFloat pageWidth = [self musicCollectionViewPageWidth] + 24;
    _currentPage = floor((self.musicCollectionView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
}

- (void)scrollViewWillEndDragging:(UIScrollView*)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint*)targetContentOffset {
    CGFloat pageWidth = [self musicCollectionViewPageWidth] +24;
    int newPage = _currentPage;
    if (velocity.x == 0) { // slow dragging not lifting finger
        newPage = floor((targetContentOffset->x - pageWidth / 2) / pageWidth) + 1;
    } else {
        newPage = velocity.x > 0 ? _currentPage + 1 : _currentPage - 1;
        if (newPage < 0)
            newPage = 0;
        if (newPage > self.musicCollectionView.contentSize.width / pageWidth)
            newPage = ceil(self.musicCollectionView.contentSize.width / pageWidth) - 1.0;
    }
    *targetContentOffset = CGPointMake((newPage * pageWidth) - kInitialContentOffsetX, targetContentOffset->y);
}

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.musicList.count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AWESingleMusicCollectionViewCell *cell =
            [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([AWESingleMusicCollectionViewCell class])
                                                      forIndexPath:indexPath];
    cell.showMore = self.showMore;
    cell.showClipButton = self.showClipButton;
    cell.musicView.delegate = self; 
    if (self.useRankIcon) {
        [cell configWithMusicModel:self.musicList[indexPath.row] rank:indexPath.row];
    } else {
        [cell configWithMusicModel:self.musicList[indexPath.row]];
    }
    return cell;
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    ACCBLOCK_INVOKE(self.selectMusicBlock, self, indexPath.row, self.musicList[indexPath.row]);
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(nonnull UICollectionViewCell *)cell forItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    // 在cell展示的时候更新状态
    AWESingleMusicCollectionViewCell *pCell = (AWESingleMusicCollectionViewCell *)cell;
    if (indexPath.row == self.playMusicIndex) {
        [pCell configWithPlayerStatus:self.playMusicStatus];
    } else {
        [pCell configWithPlayerStatus:ACCAVPlayerPlayStatusPause];
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"music_id"] = self.musicList[indexPath.row].musicID ?: @"";
    params[@"enter_from"] = @"change_music_page";
    params[@"category_name"] = [self p_getCategoryName:self.categoryName] ?: @"";
    params[@"category_id"] = self.categoryId ?: @"";
    params[@"previous_page"] = self.previousPage ?: @"";
    params[@"order"] = @(indexPath.row);
    if (self.isCommerce) {
        params[@"is_commercial"] = @1;
    }
    
    if (ACCConfigBool(kConfigBool_enable_music_selected_page_render_optims)) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [ACCTracker() trackEvent:@"show_music" params:[params copy]];
        });
    } else {
        [ACCTracker() trackEvent:@"show_music" params:[params copy]];
    }
}

#pragma mark AWESingleMusicViewDelegate

- (void)singleMusicViewDidTapUse:(AWESingleMusicView *)musicView
                           music:(id<ACCMusicModelProtocol>)music {
    if ([music isOffLine]) {
        [ACCToast() show:music.offlineDesc];
        return;
    }
    NSInteger row = [self.musicList indexOfObject:music];
    @weakify(self);
    [self showLoading];
    [ACCVideoMusic()  fetchLocalURLForMusic:music
                               withProgress:^(float progress) {}
                                 completion:^(NSURL *localURL, NSError *error) {
                                    @strongify(self);
                                    [self hideLoading];
                                    if (error) {
                                        [ACCToast() showNetWeak];
                                    } else {
                                        if (self.confirmAudioBlock) {
                                            self.confirmAudioBlock(music, error, [self categoryId], [self p_getCategoryName:self.categoryName], row);
                                        }
                                    }
    }];
}

- (void)singleMusicViewDidTapMoreButton:(id<ACCMusicModelProtocol>)music
{
    ACCBLOCK_INVOKE(self.moreButtonClicked, music, [self categoryId], [self categoryName]);
}

- (BOOL)singleMusicView:(AWESingleMusicView *)musicView
        enableClipMusic:(id<ACCMusicModelProtocol>)music
{
    if (self.enableClipBlock) {
        return self.enableClipBlock(music);
    }
    return NO;
}

- (void)singleMusicViewDidTapClip:(AWESingleMusicView *)musicView music:(id<ACCMusicModelProtocol>)music
{
    if ([music isOffLine]) {
        [ACCToast() show:music.offlineDesc];
        return;
    }
    
    [self showLoading];
    @weakify(self);
    [ACCVideoMusic() fetchLocalURLForMusic:music
                               withProgress:^(float progress) {}
                                 completion:^(NSURL *localURL, NSError *error) {
                                    @strongify(self);
                                    [self hideLoading];
                                    if (error) {
                                        [ACCToast() showNetWeak];
                                    } else {
                                        music.loaclAssetUrl = localURL;
                                        ACCBLOCK_INVOKE(self.willClipBlock, music, error);
                                    }
                                }];
}

- (void)singleMusicViewDidTapFavouriteMusic:(id<ACCMusicModelProtocol>)music 
{
    NSInteger favRow = [self.musicList indexOfObject:music];
    ACCBLOCK_INVOKE(self.favMusicBlock, music, [self categoryId], [self categoryName], favRow);
}

- (void)singleMusicViewDidTapUseWhileLoading
{
    ACCBLOCK_INVOKE(self.tapWhileLoadingBlock);
}

#pragma mark - Private

- (NSString *)categoryName {
    NSString *categoryName = @"";
    switch (self.data.type) {
        case AWEMusicCollectionDataTypeMusicCollection:
            categoryName = self.data.collectionFeed.category.name;
            break;
        case AWEMusicCollectionDataTypeMusicArray:
            categoryName = @"dmt_av_impl_recommend";
            break;
        default:
            break;
    }
    return categoryName;
}

- (NSString *)p_getCategoryName:(NSString *)categoryName
{
    if (categoryName && (self.data.type == AWEMusicCollectionDataTypeMusicArray)) {
        return @"recommend";
    }
    return categoryName;
}

- (NSString *)categoryId
{
    NSString *categoryId = @"";
    switch (self.data.type) {
        case AWEMusicCollectionDataTypeMusicCollection:
            categoryId = self.data.collectionFeed.category.idStr;
            break;
        case AWEMusicCollectionDataTypeMusicArray:
            categoryId = @"";
            break;
        default:
            break;
    }
    return categoryId;
}

- (void)setupUI
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.contentView addSubview:self.titleLabel];
    ACCMasMaker(self.titleLabel, {
        make.top.equalTo(self).offset(20);
        make.leading.equalTo(self).offset(16);
        make.bottom.equalTo(self.musicCollectionView.mas_top).offset(10);
    });
    
    [self.contentView addSubview:self.moreButton];
    ACCMasMaker(self.moreButton, {
        make.centerY.equalTo(self.titleLabel);
        make.trailing.equalTo(self).offset(-16);
    });
    
    [self.contentView addSubview:self.musicCollectionView];
    ACCMasMaker(self.musicCollectionView, {
        make.top.equalTo(self).offset(46);
        make.leading.trailing.equalTo(self);
        make.bottom.equalTo(self).offset(-10);
    });
    
    [self.contentView addSubview:self.topLineView];
    ACCMasMaker(self.topLineView, {
        make.top.equalTo(self);
        make.leading.equalTo(self).offset(16);
        make.trailing.equalTo(self).offset(-16);
        make.height.equalTo(@(1.0f / [UIScreen mainScreen].scale));
    });
}

- (void)moreButtonTapped:(UIButton *)button
{
    AWEMusicCollectionData *data = self.data;
    NSString *categoryName = @"";
    NSString *cid = @"";
    switch (data.type) {
        case AWEMusicCollectionDataTypeMusicCollection:
        {
            categoryName = data.collectionFeed.category.name;
            cid = data.collectionFeed.category.idStr;
        }
            break;
        case AWEMusicCollectionDataTypeMusicArray:
        {
            categoryName = ACCPersonalRecommendGetWords(@"music_search_music_list");
            cid = @"music_hot_list";
        }
        default:
            break;
    }
    
    NSString *URL = [NSString stringWithFormat:@"aweme://assmusic/category/%@?name=%@", cid, categoryName];
    NSDictionary *quires = @{
        @"previousPage"   : self.previousPage ?: @"",
        @"enterMethod"    : @"click_more",
        @"hideMore"       : @(!self.showMore),
        @"is_hot"         : @(data.collectionFeed.category.isHot),
        @"is_commerce"    : @(self.isCommerce),
        @"record_mode"    : @(self.recordMode),
        @"video_duration" : @(self.videoDuration),
        @"disable_cut_music" : @(self.disableCutMusic)
    };
    [IESAutoInline(ACCBaseServiceProvider(), ACCMusicViewBuilderProtocol) transitionWithURLString:URL appendQuires:quires completion:^(UIViewController * viewController) {
        if ([viewController conformsToProtocol:@protocol(HTSVideoAudioSupplier)]) {
            id<HTSVideoAudioSupplier> resultVC = (id<HTSVideoAudioSupplier>)viewController;
            resultVC.completion = self.completion;
            resultVC.enableClipBlock = self.enableClipBlock;
            resultVC.willClipBlock = self.willClipBlock;
        }
    }];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"enter_from"] = @"change_music_page";
    params[@"category_name"] = self.categoryName ?: @"";
    params[@"category_id"] = self.categoryId ?: @"";
    params[@"enter_method"] = @"click_more";
    if (self.isCommerce) {
        params[@"is_commercial"] = @1;
    }
    [ACCTracker() trackEvent:@"enter_song_category"
                                     params:[params copy]];
}

- (CGFloat)musicCollectionViewPageWidth
{
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    return screenWidth - kInitialContentOffsetX - 8 - 24;
}

#pragma mark Properties

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [ACCFont() acc_systemFontOfSize:15 weight:ACCFontWeightSemibold];
        [ACCLanguage() disableLocalizationsOfObj:_titleLabel];
        self.titleLabel.isAccessibilityElement = YES;
        self.titleLabel.accessibilityTraits = UIAccessibilityTraitHeader;
        self.titleLabel.accessibilityLabel = self.titleLabel.text;
    }
    return _titleLabel;
}

- (UIButton *)moreButton
{
    if (!_moreButton) {
        _moreButton = [[UIButton alloc] init];
        [_moreButton setTitle:@"poi_type_more" forState:UIControlStateNormal];
        _moreButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-10, -10, -10, -10);
        _moreButton.titleLabel.font = [ACCFont() acc_systemFontOfSize:13];
        [_moreButton setTitleColor:ACCResourceColor(ACCUIColorConstTextTertiary)
                          forState:UIControlStateNormal];
        [_moreButton addTarget:self action:@selector(moreButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _moreButton;
}

- (UICollectionView *)musicCollectionView
{
    if (!_musicCollectionView) {
        _musicCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.flowlayout];
        _musicCollectionView.contentInset = UIEdgeInsetsMake(0, kInitialContentOffsetX, 0, 16);
        _musicCollectionView.showsHorizontalScrollIndicator = NO;
        _musicCollectionView.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainer);
        _musicCollectionView.dataSource = self;
        _musicCollectionView.delegate = self;
        _musicCollectionView.decelerationRate = UIScrollViewDecelerationRateFast;
        [_musicCollectionView registerClass:[AWESingleMusicCollectionViewCell class]
                 forCellWithReuseIdentifier:NSStringFromClass([AWESingleMusicCollectionViewCell class])];
    }
    return _musicCollectionView;
}

- (UICollectionViewFlowLayout *)flowlayout
{
    if (!_flowlayout) {
        _flowlayout = [[UICollectionViewFlowLayout alloc] init];
        _flowlayout.minimumLineSpacing = 24;
        _flowlayout.minimumInteritemSpacing = 0;
        _flowlayout.itemSize = CGSizeMake([self musicCollectionViewPageWidth], 84);
        _flowlayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }
    return _flowlayout;
}

- (UIView *)topLineView
{
    if (!_topLineView) {
        _topLineView = [[UIView alloc] init];
        _topLineView.backgroundColor = ACCResourceColor(ACCUIColorConstLinePrimary);
    }
    return _topLineView;
}

- (void)showLoading
{
    [self hideLoading];
    self.loadingView = [ACCLoading() showLoadingAndDisableUserInteractionOnView:[UIApplication sharedApplication].keyWindow];
}

- (void)hideLoading
{
    [self.loadingView removeFromSuperview];
}

#pragma mark - UIAccessibility

- (BOOL)isAccessibilityElement
{
    return NO;
}

- (NSArray *)accessibilityElements
{
    return @[self.titleLabel, self.moreButton, self.musicCollectionView];
}

@end
