//
//  IESEffectItemCollectionCell.h
//
//  Created by Keliang Li on 2017/10/30.
//  Copyright © 2017年 keliang0420. All rights reserved.
//

#import <UIKit/UIKit.h>
@class IESEffectModel,IESEffectUIConfig;

@interface IESEffectItemCollectionCell : UICollectionViewCell
- (void)configWithDefaultWithUIConfig:(IESEffectUIConfig *)config;
- (void)configWithEffect:(IESEffectModel *)effect
                uiConfig:(IESEffectUIConfig *)config;
- (void)startDownloadAnimation;
- (void)endDownloadAnimationWithResult:(BOOL)success;
- (void)setEffectApplied:(BOOL)applied;
- (void)markAsRead;
@end
