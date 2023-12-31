//
//  ACCASSMusicBannerView.m
//  AWEStudio
//
//  Created by 旭旭 on 2018/8/31.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "ACCASSMusicBannerView.h"
#import "ACCASSMusicBannerCollectionCell.h"
#import "ACCASSMusicPageControl.h"
#import "ACCMusicViewBuilderProtocol.h"

#import <CreationKitInfra/ACCResponder.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <CreativeKit/ACCRouterProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/NSTimer+ACCAdditions.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>



static const CGFloat kPageControlW = 200;
static const CGFloat kPageControlH = 24;

@interface ACCASSMusicBannerView () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) ACCASSMusicPageControl *pageControl;

@property (nonatomic, strong) NSMutableArray *infiniteBannerList;

@property (nonatomic, strong) NSTimer *loopTimer;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) NSInteger lastIndex;

@end

@implementation ACCASSMusicBannerView

@synthesize completion = _completion, enableClipBlock = _enableClipBlock, willClipBlock = _willClipBlock;

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _canSelected = YES;
        _canAutoLoop = YES;
        [self p_setupUI];
        [self p_addObserver];
    }
    return self;
}

- (void)dealloc
{
    _collectionView.delegate = nil;
    _collectionView.dataSource = nil;
    _collectionView = nil;
    
    [self p_invalidLoopTimer];
    [self p_removeObserver];
}

#pragma mark - public method

- (void)refresh
{
    if (!_bannerList.count) {
        [self p_invalidLoopTimer];
    }
    [_collectionView reloadData];
    [self setNeedsLayout];
}


- (void)startCarousel
{
    if (_bannerList.count > 1) {
        [self p_activeLoopTimer];
    }
}

- (void)stopCarousel {
    [self p_invalidLoopTimer];
}

#pragma mark - private method

- (void)p_scrollToIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {
    if (self.infiniteBannerList.count > indexPath.item) {
        if (CGSizeEqualToSize(CGSizeZero, _collectionView.contentSize)) {
            // 如果collectionView没有contentsize，先尝试设置contentsize
            [self layoutIfNeeded];
            [self setNeedsLayout];
        }
        [_collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionNone animated:animated];
        // scrollToItemAtIndexPath这个方法并不能调用scrollViewDidScroll, 手动调用，否则currentIndex会不正确
        [self scrollViewDidScroll:_collectionView];
    }
}

#pragma mark - loop

- (void)p_activeLoopTimer {
    [self p_invalidLoopTimer];
    @weakify(self);
    _loopTimer = [NSTimer acc_timerWithTimeInterval:_autoLoopDuration block:^(NSTimer * _Nonnull timer) {
        @strongify(self);
        NSInteger currentIndex = self.currentIndex + 1;
        currentIndex = (currentIndex >= self.infiniteBannerList.count) ? 1 : currentIndex;
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:currentIndex inSection:0];
        [self p_scrollToIndexPath:indexPath animated:YES];
    } repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_loopTimer forMode:NSRunLoopCommonModes];
}

- (void)p_invalidLoopTimer {
    [_loopTimer invalidate];
    _loopTimer = nil;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat width = self.frame.size.width;
    NSInteger index = (scrollView.contentOffset.x + width * 0.5) / width;
    if (index == self.bannerList.count + 1 && scrollView.contentOffset.x >= width * (self.bannerList.count + 1)) {
        self.currentIndex = 1;
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.currentIndex inSection:0];
        [self p_scrollToIndexPath:indexPath animated:NO];
        return;
    }
    if (scrollView.contentOffset.x < width * 0.5 && scrollView.contentOffset.x <= 0) {
        self.currentIndex = self.bannerList.count;
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.currentIndex inSection:0];
        [self p_scrollToIndexPath:indexPath animated:NO];
        return;
    }
    if (_currentIndex != _lastIndex) {
        self.currentIndex = index;
    }
    _lastIndex = index;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self p_invalidLoopTimer];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (_autoLoopDuration > 0) {
        [self p_activeLoopTimer];
    }
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.canSelected) {
        return;
    }
    if (indexPath.item < self.infiniteBannerList.count) {
        id<ACCBannerModelProtocol> model = [self.infiniteBannerList acc_objectAtIndex:indexPath.item];
        [ACCTracker() trackEvent:@"banner_click"
                                         params:@{
                                                  @"enter_from" : @"change_music_page",
                                                  @"banner_id" : model.bannerID ?: @"",
                                                  @"client_order" : [NSString stringWithFormat:@"%ld", (long)indexPath.row]
                                                  }
                               ];
        if ([model.schema hasPrefix:@"aweme://assmusic/category"]) {
            NSDictionary *quires = @{
                @"previousPage"   : self.previousPage ?: @"",
                @"enterMethod"    : @"click_banner",
                @"hideMore"       : @(self.shouldHideCellMoreButton),
                @"record_mode"    : @(self.recordMode),
                @"video_duration" : @(self.videoDuration),
            };
            [IESAutoInline(ACCBaseServiceProvider(), ACCMusicViewBuilderProtocol) transitionWithURLString:model.schema appendQuires:quires completion:^(UIViewController * _Nonnull viewController) {
                if ([viewController conformsToProtocol:@protocol(HTSVideoAudioSupplier)]) {
                    id<HTSVideoAudioSupplier> resultVC = (id<HTSVideoAudioSupplier>)viewController;
                    resultVC.completion = self.completion;
                    resultVC.enableClipBlock = self.enableClipBlock;
                    resultVC.willClipBlock = self.willClipBlock;
                }
            }];
            [ACCTracker() trackEvent:@"enter_song_category"
                              params:@{
                                  @"enter_from" : @"change_music_page",
                                  @"banner_id" : model.bannerID ?: @"",
                                  @"enter_method" : @"click_banner"
                              }];
        } else if ([model.schema hasPrefix:@"aweme://music/detail"]) {
            NSArray *components = [IESAutoInline(ACCBaseServiceProvider(), ACCMusicViewBuilderProtocol) router_pathComponentArrayOfSchema:model.schema];
            NSString *musicid;
            for (NSString *string in components) {
                if ([string acc_containsNumberOnly]) {
                    musicid = string;
                }
            }
            NSString *processID = [[NSUUID UUID] UUIDString];
            NSString *currentPage = @"select_music_page";
            UIViewController *musicViewController = [ACCRouter() viewControllerForURLString:[NSString stringWithFormat:@"%@?previous_page=%@&process_id=%@&enter_from=%@", model.schema, currentPage, processID, currentPage]];
            
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:musicViewController];
            nav.modalPresentationStyle = UIModalPresentationCustom;
            nav.modalPresentationCapturesStatusBarAppearance = YES;
            nav.transitioningDelegate = self.transitionDelegate.targetTransitionDelegate;
            UIViewController *topViewController = [ACCResponder topViewController];
            [self.transitionDelegate wireToViewController:nav.topViewController];
            if (topViewController.navigationController) {
                [self.transitionDelegate setToFrame:topViewController.navigationController.view.frame];
                [topViewController.navigationController presentViewController:nav animated:YES completion:nil];
            } else {
                [self.transitionDelegate setToFrame:topViewController.view.frame];
                [topViewController presentViewController:nav animated:YES completion:nil];
            }
            [ACCTracker() trackEvent:@"enter_music_detail"
                                             params:@{
                                             @"enter_from" : @"change_music_page",
                                             @"music_id" : musicid ?: @"",
                                             @"enter_method" : @"click_banner",
                                             @"process_id" : processID,
                                             }
                                    needStagingFlag:YES];
        } else {
            NSString *schema = model.schema;
            if ([schema hasPrefix:@"http://"] || [schema hasPrefix:@"https://"]) {
                schema = [NSString stringWithFormat:@"aweme://webview?url=%@", schema];
            }
            
            if (schema) {
                [ACCRouter() transferToURLStringWithFormat:@"%@", schema];
            }
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.item > 0 && indexPath.item < self.infiniteBannerList.count - 1) {
        id<ACCBannerModelProtocol> model = self.infiniteBannerList[indexPath.item];
        if (model.bannerID.length) {
            [ACCTracker() trackEvent:@"banner_show"
                                             params:@{
                                                      @"enter_from" : @"change_music_page",
                                                      @"banner_id" : model.bannerID ?: @"",
                                                      @"client_order" : [NSString stringWithFormat:@"%ld", (long)indexPath.row]
                                                      }
                                   ];
        }
    }
}

#pragma mark - UICollectionViewDataSource

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ACCASSMusicBannerCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[ACCASSMusicBannerCollectionCell identifier] forIndexPath:indexPath];
    
    if (indexPath.item < self.infiniteBannerList.count) {
        id<ACCBannerModelProtocol> model = self.infiniteBannerList[indexPath.item];
        if (!model.bannerURL) {
            [cell refreshWithPlaceholderModel:model];
        } else {
            [cell refreshWithModel:model];
        }
    }
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.infiniteBannerList.count;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.frame.size;
}

#pragma mark - notification

- (void)p_addObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)p_removeObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationWillResignActive:(NSNotification *)noti {
    [self stopCarousel];
}

- (void)applicationDidBecomeActive:(NSNotification *)noti {
    if (_autoLoopDuration > 0) {
        [self startCarousel];
    }
}

#pragma mark - setup UI

- (void)p_setupUI {
    self.backgroundColor = ACCUIColorFromRGBA(0xFFFFF, 0.06);
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _collectionView.backgroundColor = ACCUIColorFromRGBA(0xFFFFFF, 0.06);
    _collectionView.showsHorizontalScrollIndicator = NO;
    _collectionView.pagingEnabled = YES;
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    [_collectionView registerClass:[ACCASSMusicBannerCollectionCell class] forCellWithReuseIdentifier:[ACCASSMusicBannerCollectionCell identifier]];
    [self addSubview:_collectionView];
    if (@available(iOS 11.0, *)) {
        _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    _pageControl = [[ACCASSMusicPageControl alloc] init];
    _pageControl.hidden = YES;
    _pageControl.userInteractionEnabled = NO;
    _pageControl.numberOfPages = 0;
    [self addSubview:_pageControl];
}

#pragma mark - layout

- (void)layoutSubviews {
    [super layoutSubviews];
    _collectionView.frame = self.bounds;
    CGFloat w = CGRectGetWidth(self.frame);
    CGFloat h = CGRectGetHeight(self.frame);
    _pageControl.frame = CGRectMake((w-kPageControlW)/2, h-kPageControlH, kPageControlW, kPageControlH);
}

#pragma mark - getter & setter

- (void)setAutoLoopDuration:(NSTimeInterval)autoLoopDuration
{
    if (_autoLoopDuration != autoLoopDuration) {
        _autoLoopDuration = autoLoopDuration;
        if (autoLoopDuration > 0) {
            [self p_activeLoopTimer];
        } else {
            [self p_invalidLoopTimer];
        }
    }
}

- (void)setBannerList:(NSArray *)bannerList
{
    BOOL countHasChanged = _bannerList.count != bannerList.count;
    _bannerList = [bannerList copy];
    if (_bannerList.count) {
        _infiniteBannerList = [NSMutableArray arrayWithArray:_bannerList];
        [_infiniteBannerList insertObject:[_bannerList lastObject] atIndex:0];
        [_infiniteBannerList addObject:_bannerList[0]];
        _pageControl.numberOfPages = _bannerList.count;
        if (_bannerList.count == 1) {
            _collectionView.scrollEnabled = NO;
            _pageControl.hidden = YES;
        } else {
            _pageControl.hidden = NO;
            _collectionView.scrollEnabled = YES;
        }
    } else {
        _bannerList = nil;
        _infiniteBannerList = nil;
        _pageControl.numberOfPages = 0;
    }
    [UIView transitionWithView:self.collectionView
                      duration:0.3f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^(void) {
                        [self.collectionView reloadData];
                    } completion:NULL];
    if (_bannerList.count) {
        if (_collectionView.contentOffset.x == 0 || countHasChanged) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:1 inSection:0];
            [self p_scrollToIndexPath:indexPath animated:NO];
            self.currentIndex = 1;
        }
        if (_bannerList.count > 1 && self.canAutoLoop) {
            self.autoLoopDuration = 3;
        }
    }
}

- (void)setCanAutoLoop:(BOOL)canAutoLoop
{
    _canAutoLoop = canAutoLoop;
    if (_canAutoLoop) {
        [self startCarousel];
    } else {
        [self stopCarousel];
    }
}

- (void)setCurrentIndex:(NSInteger)currentIndex
{
    _currentIndex = currentIndex;
    if (_currentIndex < _bannerList.count + 1) {
        NSInteger index = _currentIndex > 0 ? _currentIndex - 1 : 0;
        _pageControl.currentPage = index;
    }
}

@end
