//
//  ACCASMusicCategoryCollectionTableViewCell.m
//  AWEStudio
//
//  Created by 李茂琦 on 2018/9/10.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "ACCASMusicCategoryCollectionTableViewCell.h"
#import "AWEASMusicCategoryViewController.h"

@interface ACCASMusicCategoryCollectionTableViewCell ()

@property (nonatomic, strong) AWEASMusicCategoryViewController *musicCategoryVC;

@end

@implementation ACCASMusicCategoryCollectionTableViewCell

@synthesize completion = _completion, enableClipBlock = _enableClipBlock, willClipBlock = _willClipBlock;

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

+ (CGFloat)recommendedHeight:(NSInteger)numberOfCategories
{
    return [AWEASMusicCategoryViewController recommendedHeight:numberOfCategories];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setPreviousPage:(NSString *)previousPage {
    if ([_previousPage isEqualToString:previousPage]) {
        return;
    }
    _previousPage = [previousPage copy];
    self.musicCategoryVC.previousPage = previousPage;
}

- (void)setShouldHideCellMoreButton:(BOOL)shouldHideCellMoreButton {
    if (_shouldHideCellMoreButton == shouldHideCellMoreButton) {
        return;
    }
    _shouldHideCellMoreButton = shouldHideCellMoreButton;
    self.musicCategoryVC.shouldHideCellMoreButton = shouldHideCellMoreButton;
}

- (void)setDisableCutMusic:(BOOL)disableCutMusic
{
    if (_disableCutMusic == disableCutMusic) {
        return;
    }
    _disableCutMusic = disableCutMusic;
    self.musicCategoryVC.disableCutMusic = disableCutMusic;
}

- (void)setIsCommerce:(BOOL)isCommerce
{
    if (_isCommerce == isCommerce) {
        return;
    }
    _isCommerce = isCommerce;
    self.musicCategoryVC.isCommerce = isCommerce;
}

- (void)setRecordMode:(ACCServerRecordMode)recordMode
{
    if (_recordMode == recordMode) {
        return;
    }
    _recordMode = recordMode;
    self.musicCategoryVC.recordMode = recordMode;
}

- (void)setVideoDuration:(NSTimeInterval)videoDuration
{
    if (_videoDuration == videoDuration) {
        return;
    }
    _videoDuration = videoDuration;
    self.musicCategoryVC.videoDuration = videoDuration;
}

- (void)setCompletion:(HTSVideoAudioCompletion)completion {
    if (_completion == completion) {
        return;
    }
    _completion = completion;
    self.musicCategoryVC.completion = completion;
}

- (void)setEnableClipBlock:(HTSVideoAudioEnableClipBlock)enableClipBlock
{
    if (_enableClipBlock == enableClipBlock) {
        return;
    }
    _enableClipBlock = enableClipBlock;
    self.musicCategoryVC.enableClipBlock =  enableClipBlock;
}

- (void)setWillClipBlock:(HTSVideoAudioWillClipBlock)willClipBlock
{
    if (_willClipBlock == willClipBlock) {
        return;
    }
    _willClipBlock = willClipBlock;
    self.musicCategoryVC.willClipBlock = willClipBlock;
}

- (void)setupUI
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.contentView addSubview:self.musicCategoryVC.view];
    self.musicCategoryVC.view.frame = self.contentView.frame;
}

- (AWEASMusicCategoryViewController *)musicCategoryVC
{
    if (!_musicCategoryVC) {
        _musicCategoryVC = [[AWEASMusicCategoryViewController alloc] init];
    }
    return _musicCategoryVC;
}

- (void)configWithMusicCategoryModelArray:(NSArray<ACCVideoMusicCategoryModel *> *)musicCategoryModelArray
{
    [self.musicCategoryVC configWithMusicCategoryModelArray:musicCategoryModelArray];
}

#pragma mark - UIAccessibility

- (BOOL)isAccessibilityElement
{
    return NO;
}

- (NSArray *)accessibilityElements
{
    return @[self.musicCategoryVC.view];
}

@end
