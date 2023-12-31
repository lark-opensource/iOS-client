//
//  NLECaptureOutput.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/5/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NLECaptureOutput : NSObject

// 需要通过NLEInterface_OC的 - (NLECaptureOutput *)captureOutput; 获取该对象
- (instancetype)init NS_UNAVAILABLE;

- (void)getProcessedPreviewImageAtTime:(NSTimeInterval)atTime
                         preferredSize:(CGSize)size
                           isLastImage:(BOOL)isLastImage
                           compeletion:(void (^)(UIImage *image, NSTimeInterval atTime))completion;

- (UIImage *)capturePreviewUIImage;

- (void)getSourcePreviewImageAtTime:(NSTimeInterval)atTime
                      preferredSize:(CGSize)size
                        isLastImage:(BOOL)isLastImage
                        compeletion:(void (^)(UIImage *image, NSTimeInterval atTime))completion;

- (void)processImageWithCompleteBlock:(void (^)(UIImage *outputImage, NSError *error))completion;

@end

NS_ASSUME_NONNULL_END
