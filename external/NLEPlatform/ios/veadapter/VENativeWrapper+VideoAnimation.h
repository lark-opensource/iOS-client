//
//  VENativeWrapper+VideoAnimation.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/7/1.
//

#import "VENativeWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@interface VENativeWrapper (VideoAnimation)

/// 视频动画
/// @param changeInfos std::vector<SlotChangeInfo>
- (void)syncVideoAnimation:(std::vector<SlotChangeInfo> &)changeInfos;

@end

NS_ASSUME_NONNULL_END
