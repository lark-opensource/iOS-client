//
//  ACCASSelectMusicChallengeTableViewCell.h
//  AWEStudio
//
//  Created by 李茂琦 on 2018/9/10.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "AWEASMusicCellProtocol.h"
#import <CreationKitArch/ACCMusicModelProtocol.h>


@class AWESingleMusicView;

NS_ASSUME_NONNULL_BEGIN

@interface ACCASSelectMusicChallengeTableViewCell : UITableViewCell <AWEASMusicCellProtocol>

+ (NSString *)identifier;

+ (CGFloat)recommendedHeight;

- (void)configWithChallengeMusic:(id<ACCMusicModelProtocol>)challengeMusic isLastOne:(BOOL)isLastOne;

@end

NS_ASSUME_NONNULL_END
