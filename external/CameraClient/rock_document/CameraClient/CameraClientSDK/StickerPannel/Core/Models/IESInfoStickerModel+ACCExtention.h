//
//  IESInfoStickerModel+ACCExtention.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/2/28.
//

#import <EffectPlatformSDK/IESInfoStickerModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESInfoStickerModel (ACCExtention)

@property (nonatomic, assign) BOOL stickerDownloading;

@property (nonatomic, readonly, copy) NSArray *previewImgUrls;

@end

NS_ASSUME_NONNULL_END
