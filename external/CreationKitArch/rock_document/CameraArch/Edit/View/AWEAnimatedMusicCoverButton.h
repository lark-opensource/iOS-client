//
//  AWEAnimatedMusicCoverButton.h
//  Aweme
//
// Created by Liu Bing on 04 / 12 / 2017
//  Copyright © 2017 Bytedance. All rights reserved.
//

#import <CreativeKit/ACCAnimatedButton.h>
#import "ACCMusicModelProtocol.h"

@interface AWEAnimatedMusicCoverButton : ACCAnimatedButton

@property (nonatomic, assign) CGFloat ownerImageWidth;
@property (nonatomic, strong) UIImageView *ownerImageView;
@property (nonatomic, strong) UIImage *defaultCover;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) CGPoint loadingIconCenterOffset;

- (void)refreshWithMusic:(id<ACCMusicModelProtocol>)music defaultAvatarURL:(NSArray *)URLList;

@end
