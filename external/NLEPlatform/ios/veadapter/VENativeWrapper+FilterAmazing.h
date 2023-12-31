//
//  VENativeWrapper+FilterAmazing.h
//  NLEPlatform-Pods-Aweme
//
//  Created by zhangyuanming on 2021/7/27.
//

#import "VENativeWrapper.h"

NS_ASSUME_NONNULL_BEGIN

// Amazing资源

@interface VENativeWrapper (FilterAmazing)

#pragma mark - 局部

- (void)addAmazingFilter:(std::shared_ptr<cut::model::NLEFilter>)filter
                 forSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

- (void)updateAmazingFilter:(std::shared_ptr<cut::model::NLEFilter>)filter
             withPrevFilter:(std::shared_ptr<cut::model::NLEFilter>)prevFilter
                    forSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

- (void)removeAmazingFilter:(std::shared_ptr<cut::model::NLEFilter>)filter
                    forSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

#pragma mark - Global

- (void)addGlobalAmazingFilter:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

- (void)updateGlobalAmazingFilter:(std::shared_ptr<cut::model::NLETrackSlot>)slot
                         prevSlot:(std::shared_ptr<cut::model::NLETrackSlot>)prevSlot;

/// 找到所有的视频轨道，依次判断主轨和画中画是否和这个滤镜相交，并删除
/// @param slot std::shared_ptr<NLETrackSlot>  滤镜对应的slot
- (void)removeGlobalAmazingFilter:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

@end

NS_ASSUME_NONNULL_END
