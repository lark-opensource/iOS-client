//
//  VENativeWrapper+FilterKeyFrame.h
//  NLEPlatform-Pods-Aweme
//
//  Created by zhangyuanming on 2021/7/27.
//

#import "VENativeWrapper.h"

NS_ASSUME_NONNULL_BEGIN

// 滤镜关键帧

@interface VENativeWrapper (FilterKeyFrame)

- (void)syncFilterKeyFrame:(std::vector<NodeChangeInfo> &)changeInfos
                  forTrack:(std::shared_ptr<cut::model::NLETrack>)track;

@end

NS_ASSUME_NONNULL_END
