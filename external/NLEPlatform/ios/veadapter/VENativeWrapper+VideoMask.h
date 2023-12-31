//
//  VENativeWrapper+VideoMask.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/2/10.
//

#import "VENativeWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@interface VENativeWrapper (VideoMask)

/// 处理视频slot里的蒙版 、独立轨道蒙版的效果
/// @param changeInfos std::vector<SlotChangeInfo> &
- (void)syncVideoMask:(std::vector<SlotChangeInfo> &)changeInfos;

- (VEAmazingFeature *)maskCacheForSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

@end

NS_ASSUME_NONNULL_END
