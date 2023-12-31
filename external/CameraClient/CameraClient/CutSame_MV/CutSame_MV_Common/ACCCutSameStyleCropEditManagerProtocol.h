//
//  ACCCutSameStyleCropEditManagerProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by xulei on 2020/5/19.
//

#import <Foundation/Foundation.h>
#import <CameraClient/AWEVideoRangeSlider.h>
#import "ACCCutSameStylePreviewFragmentProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCCutSameStyleCropEditManagerProtocol <NSObject, AWEVideoRangeSliderDelegate>

@property (nonatomic, strong) id<ACCCutSameStylePreviewFragmentProtocol> bridgeFragment;

@end

NS_ASSUME_NONNULL_END
