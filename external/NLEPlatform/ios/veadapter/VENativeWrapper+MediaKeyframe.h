//
//   VENativeWrapper+MediaKeyframe.h
//   NLEEditor-NLEEditor
//
//   Created  by ByteDance on 2021/8/27.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    

#import "VENativeWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@interface VENativeWrapper (MediaKeyframe)

- (void)syncVideoKeyFrames:(std::vector<SlotChangeInfo>)changeInfos;

@end

NS_ASSUME_NONNULL_END
