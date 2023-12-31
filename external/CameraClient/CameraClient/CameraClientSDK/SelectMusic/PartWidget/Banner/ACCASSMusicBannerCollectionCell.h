//
//  ACCASSMusicBannerCollectionCell.h
//  AWEStudio
//
//  Created by 旭旭 on 2018/8/31.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACCMusicTransModelProtocol.h"

@interface ACCASSMusicBannerCollectionCell : UICollectionViewCell

- (void)refreshWithModel:(id<ACCBannerModelProtocol>)model;
- (void)refreshWithPlaceholderModel:(id<ACCBannerModelProtocol>)model;
+ (NSString *)identifier;

@end
