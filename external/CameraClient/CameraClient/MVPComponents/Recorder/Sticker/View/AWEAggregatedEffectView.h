//
//  AWEAggregatedEffectView.h
//  AWEStudio
//
//  Created by 李彦松 on 2018/7/8.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AWEAggregatedEffectView;
@class AWEModernStickerCollectionViewCell;
@class IESEffectModel;

@protocol ACCCameraService;

@protocol AWEAggregatedEffectViewDelegate <NSObject>

- (void)aggregatedEffectView:(AWEAggregatedEffectView *)aggregatedEffectView
         didSelectEffectCell:(AWEModernStickerCollectionViewCell *)stickerCell;
- (BOOL)aggregatedEffectView:(AWEAggregatedEffectView *)aggregatedEffectView
    shouldBeSelectedWithCell:(AWEModernStickerCollectionViewCell *)stickerCell;
- (BOOL)shouldTrackPropEvent:(AWEAggregatedEffectView *)aggregatedEffectView;
- (id<ACCCameraService>)aggregatedEffectViewCameraService;

@optional
- (NSString *)currentPropSelectedFrom;
- (NSString *)localPropId;
- (NSString *)musicId;

@end

@interface AWEAggregatedEffectView : UIView

@property(nonatomic, weak) id<AWEAggregatedEffectViewDelegate> delegate;
@property(nonatomic, copy) NSDictionary *trackingInfoDictionary;

- (void)updateAggregatedEffectArrayWith:(NSArray<IESEffectModel *> *)aggregatedArray;
- (void)updateSelectEffectWithEffect:(IESEffectModel *)selectedEffect;
- (IESEffectModel *)nextEffectOfSelectedEffect;

// EffectCell loading动画控制
- (void)setNeedLoadingAnimationForSelectedCell;
- (void)cleanLoadingSelectedCell;

@end
