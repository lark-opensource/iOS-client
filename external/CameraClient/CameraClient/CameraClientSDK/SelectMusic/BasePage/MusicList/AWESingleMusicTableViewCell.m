//
//  AWESingleMusicTableViewCell.m
//  AWEStudio
//
//  Created by 李彦松 on 2018/9/10.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWESingleMusicTableViewCell.h"
#import "ACCVideoMusicProtocol.h"
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>

#import <CreativeKit/ACCMacros.h>
#import <Masonry/View+MASAdditions.h>

const CGFloat kMusicViewContentPadding = 16.f;

@interface AWESingleMusicTableViewCell ()
@property (nonatomic, strong) UIView<ACCLoadingViewProtocol> *loadingView;
@end

@implementation AWESingleMusicTableViewCell

@synthesize musicView = _musicView, showMore = _showMore, confirmBlock = _confirmBlock, enableClipBlock = _enableClipBlock, clipBlock = _clipBlock,
moreButtonClicked = _moreButtonClicked, favouriteBlock = _favouriteBlock, tapWhileLoadingBlock = _tapWhileLoadingBlock, isEliteVersion = _isEliteVersion;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.topPadding = 12;
        [self setupUI];
    }
    return self;
}

- (void)dealloc
{
    [_loadingView dismiss];
}

#pragma mark - Public
- (instancetype)initWithNewMusicPlayerTypeWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier newPlayer:(BOOL)newPlayer {
    self = [self initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.musicView.newPlayerType = newPlayer;
        self.musicView.isFavoriteList = YES;
    }
    return self;
}

- (void)setShowMore:(BOOL)showMore
{
    if (_showMore == showMore) {
        return;
    }
    _showMore = showMore;
    self.musicView.showMoreButton = _showMore;
}

- (void)setShowExtraTopPadding:(BOOL)showExtraTopPadding
{
    if (_showExtraTopPadding == showExtraTopPadding) {
        return;
    }
    _showExtraTopPadding = showExtraTopPadding;
    [self updateTopPadding];
}

- (void)setNeedShowPGCMusicInfo:(BOOL)needShowPGCMusicInfo {
    _needShowPGCMusicInfo = needShowPGCMusicInfo;
    self.musicView.needShowPGCMusicInfo = needShowPGCMusicInfo;
}

- (void)setShowClipButton:(BOOL)showClipButton
{
    if (_showClipButton != showClipButton) {
        _showClipButton = showClipButton;
        self.musicView.showClipButton = showClipButton;
    }
}

- (void)updateTopPadding
{
    ACCMasUpdate(self.musicView, {
        make.top.equalTo(self).offset(self.showExtraTopPadding ? self.topPadding : 0);
    });
}

#pragma mark - Protocols
#pragma mark AWESingleMusicViewDelegate

- (void)singleMusicViewDidTapUse:(AWESingleMusicView *)musicView
                           music:(id<ACCMusicModelProtocol>)music
{
    [self p_didPickMusic:(id<ACCMusicModelProtocol>)music withFetchdAction:self.confirmBlock];
}

- (void)singleMusicViewDidTapMoreButton:(id<ACCMusicModelProtocol>)music
{
    ACCBLOCK_INVOKE(self.moreButtonClicked, (id<ACCMusicModelProtocol>)music);
}

- (BOOL)singleMusicView:(AWESingleMusicView *)musicView
        enableClipMusic:(id<ACCMusicModelProtocol>)music
{
    if (self.enableClipBlock) {
        return self.enableClipBlock((id<ACCMusicModelProtocol>)music);
    }
    return NO;
}

- (void)singleMusicViewDidTapClip:(AWESingleMusicView *)musicView
                            music:(id<ACCMusicModelProtocol>)music
{
    [self p_didPickMusic:music withFetchdAction:self.clipBlock];
}

- (void)singleMusicViewDidTapFavouriteMusic:(id<ACCMusicModelProtocol>)music
{
    ACCBLOCK_INVOKE(self.favouriteBlock, music);
}

- (void)singleMusicViewDidTapUseWhileLoading
{
    ACCBLOCK_INVOKE(self.tapWhileLoadingBlock);
}

#pragma mark - Private

- (void)setupUI {
    [self.contentView addSubview:self.musicView];
    ACCMasMaker(self.musicView, {
        make.top.bottom.equalTo(self);
        make.leading.equalTo(self).offset(kMusicViewContentPadding);
        make.trailing.equalTo(self).offset(-kMusicViewContentPadding);
    });
}

- (void)p_didPickMusic:(id<ACCMusicModelProtocol>)music withFetchdAction:(void(^)(id<ACCMusicModelProtocol> _Nullable, NSError * _Nullable))actionBlock
{
    if ([music isOffLine]) {
        [ACCToast() show:music.offlineDesc];
        return;
    }
    @weakify(self);
    [self.loadingView removeFromSuperview];
    self.loadingView = [ACCLoading() showLoadingAndDisableUserInteractionOnView:[UIApplication sharedApplication].keyWindow];
    [ACCVideoMusic() fetchLocalURLForMusic:music
                              withProgress:^(float progress) {}
                                completion:^(NSURL *localURL, NSError *error) {
                                      @strongify(self);
                                      [self.loadingView removeFromSuperview];
                                      if (error) {
                                          [ACCToast() showNetWeak];
                                      } else {
                                          music.loaclAssetUrl = localURL;
                                          ACCBLOCK_INVOKE(actionBlock, music, error);
                                      }
                                  }];
}

- (AWESingleMusicView *)musicView {
    if (!_musicView) {
        _musicView = [[AWESingleMusicView alloc] init];
        _musicView.contentPadding = kMusicViewContentPadding;
        _musicView.delegate = self;
    }
    return _musicView;
}

- (void)setIsEliteVersion:(BOOL)isEliteVersion
{
    _isEliteVersion = isEliteVersion;
    self.musicView.isEliteVersion = isEliteVersion;
}

+ (CGFloat)heightWithMusic:(id<ACCMusicModelProtocol>)model baseHeight:(CGFloat)baseHeight {
    return [AWESingleMusicView heightWithMusic:model
                                    baseHeight:baseHeight
                                contentPadding:kMusicViewContentPadding];
}

@end
