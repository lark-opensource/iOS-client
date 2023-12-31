//
//  VENativeWrapper+Transition.h
//  NLEPlatform
//
//  Created by bytedance on 2021/2/7.
//

#import <Foundation/Foundation.h>
#import "VENativeWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@interface VENativeWrapper (Transition)

/// 转场
/// @param changeInfos std::vector<SlotChangeInfo>
- (void)syncTransitions:(std::vector<SlotChangeInfo> &)changeInfos;

- (void)updateTransitionComparePrevSlot:(std::shared_ptr<cut::model::NLETrackSlot>)prevSlot
                                newSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

- (void)updateTransitionForSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot
                       prevSlot:(std::shared_ptr<cut::model::NLETrackSlot>)prevSlot;

- (void)removeTransitionForSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

@end

NS_ASSUME_NONNULL_END
