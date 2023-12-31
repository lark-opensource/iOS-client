//
//  ACCEditEffectProtocolD.h
//  CameraClient
//
//  Created by yangying on 2021/6/17.
//

#ifndef ACCEditEffectProtocolD_h
#define ACCEditEffectProtocolD_h

#import <CreationKitRTProtocol/ACCEditEffectProtocol.h>
#import "ACCEditVideoDataProtocol.h"

@protocol ACCEditEffectProtocolD <ACCEditEffectProtocol>

- (void)appendComposerNodes:(NSArray <VEComposerInfo *>*)nodes videoData:(ACCEditVideoData *)videoData;
- (void)changeSpeedWithVideoData:(ACCEditVideoData *)videoData xPoints:(NSArray <NSNumber *>*)xPoints yPoints:(NSArray <NSNumber *>*)yPoints assetIndex:(NSInteger)assetIndex;

@end


#endif /* ACCEditEffectProtocolD_h */
