//
//  IESMMCanvasSource+NLE.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/7/1.
//

#import <TTVideoEditor/IESMMCanvasSource.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESMMCanvasSource (NLE)

- (BOOL)nle_equalToCanvasSource:(IESMMCanvasSource *)source;

@end

NS_ASSUME_NONNULL_END
