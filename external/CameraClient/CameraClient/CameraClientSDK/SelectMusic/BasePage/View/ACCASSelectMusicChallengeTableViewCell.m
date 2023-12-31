//
//  ACCASSelectMusicChallengeTableViewCell.m
//  AWEStudio
//
//  Created by 李茂琦 on 2018/9/10.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "ACCASSelectMusicChallengeTableViewCell.h"
#import "AWESingleMusicView.h"
#import "ACCVideoMusicProtocol.h"

#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSNumber+CameraClientResource.h>
#import <CreativeKit/UIColor+CameraClientResource.h>

static NSString * const kVerticalPaddingKey = @"acc.music_challenge_cell.vertical_padding";

@interface ACCASSelectMusicChallengeTableViewCell () <AWESingleMusicViewDelegate>

@property (nonatomic, strong) UIView *bottomLineView;
@property (nonatomic, assign) BOOL isLastOne;
@property (nonatomic, strong) UIView<ACCLoadingViewProtocol> *loadingView;

@end

@implementation ACCASSelectMusicChallengeTableViewCell

@synthesize musicView = _musicView, showMore = _showMore, confirmBlock = _confirmBlock, enableClipBlock = _enableClipBlock, clipBlock = _clipBlock,
moreButtonClicked = _moreButtonClicked, favouriteBlock = _favouriteBlock, tapWhileLoadingBlock = _tapWhileLoadingBlock, isEliteVersion = _isEliteVersion, showClipButton = _showClipButton;

- (void)dealloc
{
    [_loadingView removeFromSuperview];
}

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

+ (CGFloat)recommendedHeight
{
    return 76.f + [self verticalPadding];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.contentView addSubview:self.musicView];
    [self.contentView addSubview:self.bottomLineView];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat w = self.contentView.bounds.size.width - 16 * 2;
    CGFloat h = self.contentView.bounds.size.height;
    self.musicView.frame = CGRectMake(16 + 8, 0, w - 16, 60 + 8 + 16);//singleView高度增加到84了
    CGFloat lineH = 1.f / [UIScreen mainScreen].scale;
    self.bottomLineView.frame = CGRectMake(16, h - lineH, w, lineH);
}

- (void)setShowMore:(BOOL)showMore {
    if (_showMore == showMore) {
        return;
    }
    _showMore = showMore;
    self.musicView.showMoreButton = _showMore;
}

- (void)setShowClipButton:(BOOL)showClipButton
{
    if (_showClipButton != showClipButton) {
        _showClipButton = showClipButton;
        self.musicView.showClipButton = showClipButton;
    }
}

- (UIView *)bottomLineView
{
    if (!_bottomLineView) {
        _bottomLineView = [[UIView alloc] init];
        _bottomLineView.backgroundColor = ACCResourceColor(ACCUIColorLinePrimary);
    }
    return _bottomLineView;
}

- (AWESingleMusicView *)musicView
{
    if (!_musicView) {
        _musicView = [[AWESingleMusicView alloc] init];
        _musicView.delegate = self;
    }
    return _musicView;
}

+ (CGFloat)verticalPadding
{
    return ACCFloatConfig(kVerticalPaddingKey);
}

- (void)configWithChallengeMusic:(id<ACCMusicModelProtocol>)challengeMusic isLastOne:(BOOL)isLastOne
{
    [self.musicView configWithMusicModel:challengeMusic];
    self.isLastOne = isLastOne;
    self.bottomLineView.hidden = NO; 
}

#pragma mark - AWESingleMusicViewDelegate

- (void)singleMusicViewDidTapUse:(AWESingleMusicView *)musicView
                           music:(id<ACCMusicModelProtocol>)music
{
    [self p_didPickMusic:music withFetchdAction:self.confirmBlock];
}

- (void)singleMusicViewDidTapMoreButton:(id<ACCMusicModelProtocol>)music
{
    ACCBLOCK_INVOKE(self.moreButtonClicked, music);
}

- (void)singleMusicViewDidTapFavouriteMusic:(id<ACCMusicModelProtocol>)music
{
    ACCBLOCK_INVOKE(self.favouriteBlock, music);
}

- (void)singleMusicViewDidTapUseWhileLoading
{
    ACCBLOCK_INVOKE(self.tapWhileLoadingBlock);
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
    [self p_didPickMusic:music withFetchdAction:self.clipBlock];
}

- (void)p_didPickMusic:(id<ACCMusicModelProtocol>)music withFetchdAction:(void(^)(id<ACCMusicModelProtocol> _Nullable, NSError * _Nullable))actionBlock
{
    if ([music isOffLine]) {
        [ACCToast() show:music.offlineDesc];
        return;
    }
    [self.loadingView removeFromSuperview];
    self.loadingView = [ACCLoading() showLoadingAndDisableUserInteractionOnView:[UIApplication sharedApplication].keyWindow];
    @weakify(self);
    [ACCVideoMusic() fetchLocalURLForMusic:music
                              withProgress:^(float progress) {}
                                completion:^(NSURL *localURL, NSError *error) {
                                    @strongify(self);
                                    [self.loadingView removeFromSuperview];
                                    if (error) {
                                        [ACCToast() showNetWeak];
                                    } else {
                                        ACCBLOCK_INVOKE(actionBlock, music, error);
                                    }
                                }];
}

@end
