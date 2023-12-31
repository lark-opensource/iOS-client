//
//  ACCShootSameStickerConfigDelegation.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/8/3.
//

#import <Foundation/Foundation.h>

@protocol ACCShootSameStickerConfigDelegation

@optional

- (void)didTapSelectTime;
- (void)didTapPreview:(nullable NSString *)awemeId;

@end
