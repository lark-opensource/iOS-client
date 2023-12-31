//
//  ACCEditMusicProtocol.h
//  CameraClient
//
//  Created by haoyipeng on 2020/9/10.
//

#import <Foundation/Foundation.h>
#import "ACCEditWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditHDRProtocol <ACCEditWrapper>

- (void)enableLensHDRWithModelPath:(NSString *)modelPath;
- (void)disableLensHDR;


- (void)enableOneKeyHDRWithModel:(NSString *)modelPath
                  disableDenoise:(BOOL)disableDenoise
                         asfMode:(NSInteger)asfMode
                         hdrMode:(NSInteger)hdrMode;
- (void)disableOneKeyHDR;

- (int)currentScene;
- (BOOL)shouldUseDenoise;

@end

NS_ASSUME_NONNULL_END
