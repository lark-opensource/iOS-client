//
//  ACCTextStickerCacheHelper.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCTextStickerCacheHelper : NSObject

+ (void)updateLastSelectedSpeaker:(NSString *)speakerID;
+ (nullable NSString *)getLastSelectedSpeaker;

@end

NS_ASSUME_NONNULL_END
