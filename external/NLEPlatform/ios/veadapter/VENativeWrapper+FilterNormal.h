//
//  VENativeWrapper+FilterNormal.h
//  NLEPlatform-Pods-Aweme
//
//  Created by zhangyuanming on 2021/7/27.
//

#import "VENativeWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@interface VENativeWrapper (FilterNormal)

#pragma mark - 局部

- (void)addNormalFilter:(std::shared_ptr<cut::model::NLEFilter>)filter
                forSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

- (void)updateNormalFilter:(std::shared_ptr<cut::model::NLEFilter>)filter
            withPrevFilter:(std::shared_ptr<cut::model::NLEFilter>)prevFilter
                   forSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

- (void)removeNormalFilter:(std::shared_ptr<cut::model::NLEFilter>)filter
                   forSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot;


#pragma mark - Global

- (void)addGlobalNormalFilter:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

- (void)updateGlobalNormalFilter:(std::shared_ptr<cut::model::NLETrackSlot>)slot
                        prevSlot:(std::shared_ptr<cut::model::NLETrackSlot>)prevSlot;

/// 删除普通类型的全局滤镜：composer 滤镜、抖音普通滤镜、HDR、Lens_HDR
/// @param slot std::shared_ptr<NLETrackSlot>
- (void)removeGlobalNormalFilter:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

@end

NS_ASSUME_NONNULL_END
