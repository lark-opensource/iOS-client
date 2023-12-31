//
//  AWESingleMusicCollectionViewCell.h
//  AWEStudio
//
//  Created by 李彦松 on 2018/9/7.
//  Copyright © 2018年 bytedance. All rights reserved.
//


#import <CreationKitArch/ACCMusicModelProtocol.h>
#import <CameraClient/ACCAudioPlayerProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@class AWESingleMusicView;
@interface AWESingleMusicCollectionViewCell : UICollectionViewCell

@property(nonatomic, strong, readonly) AWESingleMusicView *musicView;

@property (nonatomic, assign) BOOL showMore;
@property (nonatomic, assign) BOOL showClipButton;

- (void)configWithMusicModel:(id<ACCMusicModelProtocol>)model;
- (void)configWithMusicModel:(id<ACCMusicModelProtocol>)model rank:(NSInteger)rank;

- (void)configWithPlayerStatus:(ACCAVPlayerPlayStatus)playerStatus;

@end

NS_ASSUME_NONNULL_END
