//
//  AWESwitchRecordModeCollectionViewCell.h
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/3/13.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CreativeKit/ACCMacros.h>

@class AWESwitchModeSingleTabConfig;

FOUNDATION_EXPORT NSString *const kACCTextModeRedDotAppearedOnceKey;

static inline CGSize FlowerEntrySize(){
    static CGSize flowerEntrySize = {76, 30};
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (ACC_SCREEN_WIDTH < 375) {
            flowerEntrySize = CGSizeMake(76, 30);
        } else {
            flowerEntrySize = CGSizeMake(84, 30);
        }
    });
    return flowerEntrySize;
}

static inline CGSize FlowerArrowSize(){
    static CGSize flowerArrowSize = {10, 11};
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (ACC_SCREEN_WIDTH < 375) {
            flowerArrowSize = CGSizeMake(10, 11);
        } else {
            flowerArrowSize = CGSizeMake(12, 12);
        }
    });
    return flowerArrowSize;
}
    
@interface AWESwitchRecordModeCollectionViewCell : UICollectionViewCell

- (void)buildWithTabConfig:(AWESwitchModeSingleTabConfig *)tabConfig;
- (void)refreshColorWithSelected:(BOOL)selected uiColor:(UIColor *)color;
- (void)refreshColorWithUIStyle:(BOOL)blackStyle normalColor:(UIColor *)normalColor selectedColor:(UIColor *)selectedColor animated:(BOOL)animated;
- (void)configCellWithUIStyle:(BOOL)blackStyle selected:(BOOL)selected color:(UIColor *)color animated:(BOOL)animated;
+ (NSInteger)cellWidthWithTabConfig:(AWESwitchModeSingleTabConfig *)tabConfig;
+ (NSString *)identifier;
- (void)showRedDot:(BOOL)show;
- (void)showTopRightTipIfNeeded;
- (void)showFlowerViewIfNeeded:(BOOL)show animated:(BOOL)animated;

@end
