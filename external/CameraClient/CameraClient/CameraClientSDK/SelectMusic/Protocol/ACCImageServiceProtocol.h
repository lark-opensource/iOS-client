//
//  ACCImageServiceProtocol.h
//  CameraClient
//
//  Created by xiaojuan on 2020/9/7.
//

#import <Foundation/Foundation.h>

#import "ACCMusicEnumDefines.h"

#ifndef ACCImageServiceProtocol_h
#define ACCImageServiceProtocol_h

@protocol ACCImageServiceProtocol <NSObject>

- (CGSize)getWebImageSizeWithType:(ACCImageGearType)type;

- (UIImage *)getBackImageForMusicSelectVCWithBackStatus:(BOOL)back;

@end
#endif /* ACCImageServiceProtocol_h */
