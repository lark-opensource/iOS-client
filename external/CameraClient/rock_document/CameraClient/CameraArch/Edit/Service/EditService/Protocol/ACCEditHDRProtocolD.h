//
//  ACCEditHDRProtocolD.h
//  CameraClient
//
//  Created by yangying on 2021/6/21.
//

#ifndef ACCEditHDRProtocolD_h
#define ACCEditHDRProtocolD_h

#import "ACCEditVideoDataProtocol.h"
#import <CreationKitRTProtocol/ACCEditHDRProtocol.h>

@protocol ACCEditHDRProtocolD <ACCEditHDRProtocol>

- (void)startMatchingAlgorithmWithVideoData:(id<ACCEditVideoDataProtocol>)videoData completion:(void (^)(int))completion;

- (int)detectHDRScene;

@end

#endif /* ACCEditHDRProtocolD_h */
