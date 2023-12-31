//
//  BDImageSuperResolution.h
//  BDWebImageToB
//
//  Created by 陈奕 on 2020/11/5.
//
#if __is_target_arch(arm64) || __is_target_arch(arm64e)
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDImageSuperResolution : NSObject

+ (UIImage *)superResolutionImageWithImage:(UIImage *)image error:(NSError * _Nullable __autoreleasing *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
#endif
