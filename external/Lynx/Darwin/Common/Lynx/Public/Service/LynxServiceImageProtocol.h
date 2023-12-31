//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICEIMAGEPROTOCOL_H_
#define DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICEIMAGEPROTOCOL_H_
#import <Foundation/Foundation.h>
#ifdef OS_IOS
#import <UIKit/UIKit.h>
#import "LynxServiceProtocol.h"
#import "LynxUIImage.h"

NS_ASSUME_NONNULL_BEGIN
typedef void (^LynxImageLoadCompletionBlock)(UIImage *_Nullable image, NSError *_Nullable error,
                                             NSURL *_Nullable imageURL);

@protocol LynxServiceImageProtocol <LynxServiceProtocol>

- (UIImageView *)imageView;
- (dispatch_block_t)loadNewImageFromURL:(LynxURL *)url
                                   size:(CGSize)targetSize
                            contextInfo:(NSDictionary *)contextInfo
                             processors:(NSArray *)processors
                              completed:(LynxImageLoadCompletionBlock)completed
                            LynxUIImage:(LynxUIImage *)lynxUIImage;

- (void)reportResourceStatus:(LynxView *)LynxView
                        data:(NSMutableDictionary *)data
                       extra:(NSDictionary *__nullable)extra;

- (NSNumber *)getMappedCategorizedPicErrorCode:(NSNumber *)errorCode;

- (void)prefetchImage:(LynxURL *)url params:(nullable NSDictionary *)params;

@optional
- (UIImage *)decodeImage:(NSData *)data;
- (void)handleAnimatedImage:(UIImage *)image
                       view:(UIImageView *)imageView
                  loopCount:(NSInteger)loopCount;

@end

NS_ASSUME_NONNULL_END
#endif  // OS_IOS
#endif  // DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICEIMAGEPROTOCOL_H_
