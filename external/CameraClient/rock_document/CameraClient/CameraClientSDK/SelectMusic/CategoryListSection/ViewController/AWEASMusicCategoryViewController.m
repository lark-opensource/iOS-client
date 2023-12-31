//
//  AWEASMusicCategoryViewController.m
//  AWEStudio
//
//  Created by 李茂琦 on 2018/9/4.
//  Copyright © 2018 bytedance. All rights reserved.
//


#import "AWEASMusicCategoryViewController.h"
#import "ACCVideoMusicCategoryModel.h"
#import "AWEASMusicCategoryCollectionViewCell.h"
#import "ACCMusicViewBuilderProtocol.h"

#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCTrackProtocol.h>


const CGFloat AWEASMusicCategoryViewMargin = 20.f;
const CGFloat AWEASMusicCategoryCollectionViewCellHeight = 32.f;
const CGFloat AWEASMusicCategoryCollectionViewCellMargin = 16.f;
const CGFloat AWEASMusicCategoryCollectionViewTopHeight = 18.f;

@interface AWEASMusicCategoryViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UIView *topLineView;
@property (nonatomic, strong) UILabel *topLeftLabel;
@property (nonatomic, strong) UIButton *topRightButton;
@property (nonatomic, strong) UICollectionView *musicCategoryCollectionView;

@property (nonatomic, copy) NSArray<ACCVideoMusicCategoryModel *> *dataList;

@end

@implementation AWEASMusicCategoryViewController

@synthesize completion = _completion, enableClipBlock = _enableClipBlock, willClipBlock = _willClipBlock;

+ (CGFloat)recommendedHeight:(NSUInteger)numberOfCategories
{
    CGFloat height = 1.0f / [UIScreen mainScreen].scale + AWEASMusicCategoryViewMargin * 3 + AWEASMusicCategoryCollectionViewTopHeight;
    NSUInteger numberOfRows = (NSUInteger)ceil(numberOfCategories / 2.f);
    height += (numberOfRows * AWEASMusicCategoryCollectionViewCellHeight + (numberOfRows - 1) * AWEASMusicCategoryCollectionViewCellMargin);
    return height;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _dataList = [[NSArray alloc] init];
        self.view.isAccessibilityElement = NO;
        self.view.shouldGroupAccessibilityChildren = YES;
        self.shouldGroupAccessibilityChildren = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupUI];
}

#pragma mark - Private

- (void)setupUI
{
    self.view.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainer);
    
    [self.view addSubview:self.topLineView];
    [self.view addSubview:self.topLeftLabel];
    [self.view addSubview:self.topRightButton];
    [self.view addSubview:self.musicCategoryCollectionView];
}

#pragma mark - Getter

- (UIView *)topLineView
{
    if (!_topLineView) {
        CGFloat width = self.view.acc_width - AWEASMusicCategoryCollectionViewCellMargin * 2;
        CGFloat height = 1.0f / [UIScreen mainScreen].scale;
        _topLineView = [[UIView alloc] initWithFrame:CGRectMake(AWEASMusicCategoryCollectionViewCellMargin, 0.f, width, height)];
        _topLineView.backgroundColor = ACCResourceColor(ACCUIColorConstLinePrimary);
    }
    return _topLineView;
}

- (UILabel *)topLeftLabel
{
    if (!_topLeftLabel) {
        CGFloat width = 65.f;
        CGFloat height = AWEASMusicCategoryCollectionViewTopHeight;
        _topLeftLabel = [[UILabel alloc] initWithFrame:CGRectMake(AWEASMusicCategoryCollectionViewCellMargin, 0, width, height)];
        _topLeftLabel.acc_top = self.topLineView.acc_bottom + AWEASMusicCategoryViewMargin;
        _topLeftLabel.font = [ACCFont() acc_systemFontOfSize:15.f weight:ACCFontWeightMedium];
        _topLeftLabel.text = @"play_list";
        [_topLeftLabel sizeToFit];
    }
    return _topLeftLabel;
}

- (UIButton *)topRightButton
{
    if (!_topRightButton) {
        CGFloat width = 57.f;
        CGFloat height = AWEASMusicCategoryCollectionViewTopHeight;
        _topRightButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        _topRightButton.titleLabel.font = [ACCFont() acc_systemFontOfSize:13.f weight:ACCFontWeightRegular];
        [_topRightButton setTitle:@"poi_type_more" forState:UIControlStateNormal];
        [_topRightButton setTitle:@"poi_type_more" forState:UIControlStateHighlighted];
        [_topRightButton setTitleColor:ACCResourceColor(ACCUIColorConstTextTertiary) forState:UIControlStateNormal];
        [_topRightButton setTitleColor:ACCResourceColor(ACCUIColorConstTextTertiary) forState:UIControlStateHighlighted];
        [_topRightButton acc_addSingleTapRecognizerWithTarget:self action:@selector(didTapAllCategory)];
        [_topRightButton.titleLabel sizeToFit];
        [_topRightButton sizeToFit];
        _topRightButton.acc_centerY = self.topLeftLabel.acc_centerY;
        _topRightButton.acc_right = self.view.acc_width - AWEASMusicCategoryCollectionViewCellMargin;
    }
    return _topRightButton;
}

- (UICollectionView *)musicCategoryCollectionView
{
    if (!_musicCategoryCollectionView) {
        CGFloat width = self.view.acc_width - AWEASMusicCategoryCollectionViewCellMargin * 2;
        CGFloat height = [self collectionViewHeight];
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumLineSpacing = 16.f;
        layout.minimumInteritemSpacing = 16.f;
        _musicCategoryCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(AWEASMusicCategoryCollectionViewCellMargin, 0, width, height) collectionViewLayout:layout];
        _musicCategoryCollectionView.acc_top = self.topRightButton.acc_bottom + AWEASMusicCategoryViewMargin;
        _musicCategoryCollectionView.acc_height = [self collectionViewHeight];
        _musicCategoryCollectionView.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainer);
        _musicCategoryCollectionView.scrollEnabled = NO;
        [_musicCategoryCollectionView registerClass:AWEASMusicCategoryCollectionViewCell.class forCellWithReuseIdentifier:[AWEASMusicCategoryCollectionViewCell identifier]];
        _musicCategoryCollectionView.delegate = self;
        _musicCategoryCollectionView.dataSource = self;
    }
    return _musicCategoryCollectionView;
}

#pragma mark - Public

- (void)configWithMusicCategoryModelArray:(NSArray<ACCVideoMusicCategoryModel *> *)musicCategoryModelArray
{
    if (ACC_isEmptyArray(musicCategoryModelArray)) {
        return ;
    }
    self.dataList = musicCategoryModelArray;
    self.musicCategoryCollectionView.acc_height = [self collectionViewHeight];
    [self.musicCategoryCollectionView reloadData];
}

#pragma mark - helper

- (CGFloat)collectionViewHeight
{
    if (ACC_isEmptyArray(self.dataList)) {
        return 0.f;
    }
    NSUInteger numberOfRows = (NSUInteger)ceil(self.dataList.count / 2.f);
    return numberOfRows * AWEASMusicCategoryCollectionViewCellHeight + (numberOfRows - 1) * AWEASMusicCategoryCollectionViewCellMargin;
}

- (void)didTapAllCategory
{
    @weakify(self);
    NSString *URLString = [NSString stringWithFormat:@"aweme://select_music/category/?previousPage=%@&hideMore=%@&is_commerce=%@&record_mode=%@&video_duration=%@", self.previousPage ?: @"", self.shouldHideCellMoreButton ? @"1" : @"0", self.isCommerce ? @"1" : @"0", @(self.recordMode), @(self.videoDuration)];
    
    if (self.disableCutMusic) {
        URLString = [URLString stringByAppendingFormat:@"&disable_cut_music=%@", @(self.disableCutMusic)];
    }
    
    [IESAutoInline(ACCBaseServiceProvider(), ACCMusicViewBuilderProtocol) transitionWithURLString:URLString completion:^(UIViewController * viewController) {
        @strongify(self);
        if ([viewController conformsToProtocol:@protocol(HTSVideoAudioSupplier)]) {
            id<HTSVideoAudioSupplier> resultVC = (id<HTSVideoAudioSupplier>)viewController;
            resultVC.completion = self.completion;
            resultVC.enableClipBlock = self.enableClipBlock;
            resultVC.willClipBlock = self.willClipBlock;
        }
    }];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // todo: @liyansong 切换到新的音乐歌单页面
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    NSUInteger index = indexPath.row;
    if (!ACC_isEmptyArray(self.dataList) && index < self.dataList.count) {
        ACCVideoMusicCategoryModel *model = [self.dataList acc_objectAtIndex:index];
        NSString *URL = [NSString stringWithFormat:@"aweme://assmusic/category/%@?name=%@", model.idStr, model.name];
        NSDictionary *quires = @{
            @"previousPage"   : self.previousPage ?: @"",
            @"enterMethod"    : @"click_category_list",
            @"hideMore"       : @(self.shouldHideCellMoreButton),
            @"is_hot"         : @(model.isHot),
            @"is_commerce"    : @(self.isCommerce),
            @"record_mode"    : @(self.recordMode),
            @"video_duration" : @(self.videoDuration),
            @"disable_cut_music": @(self.disableCutMusic)
        };
        [IESAutoInline(ACCBaseServiceProvider(), ACCMusicViewBuilderProtocol) transitionWithURLString:URL appendQuires:quires completion:^(UIViewController *viewController) {
            if ([viewController conformsToProtocol:@protocol(HTSVideoAudioSupplier)]) {
                id<HTSVideoAudioSupplier> resultVC = (id<HTSVideoAudioSupplier>)viewController;
                resultVC.completion = self.completion;
                resultVC.enableClipBlock = self.enableClipBlock;
                resultVC.willClipBlock = self.willClipBlock;
            }
        }];

        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        params[@"enter_from"] = @"change_music_page";
        params[@"category_name"] = model.name ?: @"";
        params[@"category_id"] = model.idStr ?: @"";
        params[@"enter_method"] = @"click_category_list";
        if (self.isCommerce) {
            params[@"is_commercial"] = @1;
        }
        [ACCTracker() trackEvent:@"enter_song_category"
                          params:[params copy]];
    }
}

#pragma mark - UICollectionViewDatasource

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    AWEASMusicCategoryCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[AWEASMusicCategoryCollectionViewCell identifier] forIndexPath:indexPath];
    ACCVideoMusicCategoryModel *model = [self.dataList acc_objectAtIndex:indexPath.row];
    [cell configWithMusicCategoryModel:model];
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return ACC_isEmptyArray(self.dataList) ? 0 : self.dataList.count;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake((self.musicCategoryCollectionView.acc_width - AWEASMusicCategoryCollectionViewCellMargin) / 2.f, [AWEASMusicCategoryCollectionViewCell recommendedHeight]);
}

#pragma mark - UIAccessibility

- (BOOL)isAccessibilityElement
{
    return NO;
}

- (NSArray *)accessibilityElements
{
    return @[self.topLeftLabel, self.topRightButton, self.musicCategoryCollectionView];
}

@end
