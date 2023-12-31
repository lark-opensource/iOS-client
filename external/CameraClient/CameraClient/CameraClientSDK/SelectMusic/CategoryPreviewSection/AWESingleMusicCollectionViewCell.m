//
//  AWESingleMusicCollectionViewCell.m
//  AWEStudio
//
//  Created by 李彦松 on 2018/9/7.
//  Copyright © 2018年 bytedance. All rights reserved.
//


#import "AWESingleMusicCollectionViewCell.h"
#import "AWESingleMusicView.h"

#import <CreationKitInfra/UIView+ACCMasonry.h>

#import <Masonry/View+MASAdditions.h>


@interface AWESingleMusicCollectionViewCell ()

@property (nonatomic, strong, readwrite) AWESingleMusicView *musicView;

@end

@implementation AWESingleMusicCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

#pragma mark - Public

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

- (void)configWithMusicModel:(id<ACCMusicModelProtocol>)model
{
    [self.musicView configWithMusicModel:model];
}

- (void)configWithMusicModel:(id<ACCMusicModelProtocol>)model rank:(NSInteger)rank
{
    [self.musicView configWithMusicModel:model rank:rank];
}

- (void)configWithPlayerStatus:(ACCAVPlayerPlayStatus)playerStatus
{
    [self.musicView configWithPlayerStatus:playerStatus];
}

#pragma mark - Private

- (void)setupUI {
    [self.contentView addSubview:self.musicView];
    self.musicView.showMoreButton = self.showMore;
    ACCMasMaker(self.musicView, {
        make.top.equalTo(self);
        make.bottom.equalTo(self);
        make.left.right.equalTo(self);
    });
}

- (AWESingleMusicView *)musicView {
    if (!_musicView) {
        _musicView = [[AWESingleMusicView alloc] init];
    }
    return _musicView;
}

@end
