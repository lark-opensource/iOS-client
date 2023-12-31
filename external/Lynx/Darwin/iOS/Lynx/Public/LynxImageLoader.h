// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxImageFetcher.h"
NS_ASSUME_NONNULL_BEGIN

@interface LynxImageLoader : NSObject

+ (nonnull instancetype)sharedInstance;

/**
 Load image from remote. After image downloaded, processors will be use to preprocesse
 image in order on background thread. Completed block will be called after every
 thing prepare on main thread

 @param url         the image url
 @param processors  processor list to process image
 @param completed   callback when image ready
 */
- (dispatch_block_t)loadImageFromURL:(NSURL*)url
                                size:(CGSize)targetSize
                         contextInfo:(NSDictionary*)contextInfo
                          processors:(NSArray*)processors
                        imageFetcher:(id<LynxImageFetcher>)imageFetcher
                           completed:(LynxImageLoadCompletionBlock)completed;

/**
Load image from remote. After image downloaded, processors will be use to preprocesse
image in order on background thread. Completed block will be called after every
thing prepare on main thread

@param url         the image url
@param processors  processor list to process image
@param completed   callback when image ready
*/
- (dispatch_block_t)loadCanvasImageFromURL:(NSURL*)url
                               contextInfo:(NSDictionary*)contextInfo
                                processors:(NSArray*)processors
                              imageFetcher:(id<LynxImageFetcher>)imageFetcher
                                 completed:(LynxCanvasImageLoadCompletionBlock)completed;

@end
#if defined __cplusplus
extern "C" {
#endif
BOOL LynxImageFetchherSupportsProcessor(id<LynxImageFetcher> fetcher);
#if defined __cplusplus
};
#endif
NS_ASSUME_NONNULL_END
