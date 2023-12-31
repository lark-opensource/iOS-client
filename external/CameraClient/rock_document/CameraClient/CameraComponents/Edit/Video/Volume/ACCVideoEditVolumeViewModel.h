//
//  ACCVideoEditVolumeViewModel.h
//  CameraClient-Pods-Aweme
//
//  Created by HuangHongsen on 2020/8/10.
//

#import "ACCEditVolumeServiceProtocol.h"


NS_ASSUME_NONNULL_BEGIN

@interface ACCVideoEditVolumeViewModel : NSObject <ACCEditVolumeServiceProtocol>

- (void)sendCheckMusicFeatureToastSignal;

@end

NS_ASSUME_NONNULL_END
