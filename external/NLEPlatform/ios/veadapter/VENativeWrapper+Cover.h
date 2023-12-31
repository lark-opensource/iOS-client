//
//  VENativeWrapper+Cover.h
//  NLEPlatform-Pods-Aweme
//
//  Created by zhangyuanming on 2021/8/23.
//

#import "VENativeWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@interface VENativeWrapper (Cover)

- (void)incrementBuildWithPrevCoverModel:(std::shared_ptr<cut::model::NLEVideoFrameModel>)prevCoverModel
                           curCoverModel:(std::shared_ptr<cut::model::NLEVideoFrameModel>)curCoverModel
                              completion:(NLEBaseBlock)completion;

@end

NS_ASSUME_NONNULL_END
