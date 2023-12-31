// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LynxImageProcessor.h"

NS_ASSUME_NONNULL_BEGIN
@class LynxUI;

typedef void (^LynxImageLoadCompletionBlock)(UIImage* _Nullable image, NSError* _Nullable error,
                                             NSURL* _Nullable imageURL);

typedef void (^LynxCDNResourceLoadCompletionBlock)(NSData* _Nullable data, NSError* _Nullable error,
                                                   NSURL* _Nullable dataPathURL);

typedef void (^LynxCanvasImageLoadCompletionBlock)(NSData* _Nullable image,
                                                   NSError* _Nullable error,
                                                   NSURL* _Nullable imageURL);

FOUNDATION_EXPORT NSString* const LynxImageFetcherContextKeyUI;
FOUNDATION_EXPORT NSString* const LynxImageFetcherContextKeyLynxView;
FOUNDATION_EXPORT NSString* const LynxImageFetcherContextKeyDownsampling;
FOUNDATION_EXPORT NSString* const LynxImageRequestOptions;

@protocol LynxImageFetcher <NSObject>

/*!
 Load image asynchronously.
 @param ui: ui that fires the request.
 @param url: target image url.
 @param targetSize: the target screen size for showing the image. It is more efficient that UIImage
   with the same size is returned.
 @param contextInfo: extra info needed for image request.
 @param completionBlock: the block to provide image fetcher result.
 @return: A block which can cancel the image request if it is not finished. nil if cancel action is
   not supported.
*/
@optional
- (dispatch_block_t)loadImageWithURL:(NSURL*)url
                                size:(CGSize)targetSize
                         contextInfo:(nullable NSDictionary*)contextInfo
                          completion:(LynxImageLoadCompletionBlock)completionBlock;

@optional
- (dispatch_block_t)loadImageWithURL:(NSURL*)url
                          processors:(NSArray<id<LynxImageProcessor>>*)processors
                                size:(CGSize)targetSize
                         contextInfo:(NSDictionary*)contextInfo
                          completion:(LynxImageLoadCompletionBlock)completionBlock;

/**
 Load image asynchronously.
 @url: target image url.
 @targetSize: the target screen size for showing the image. It is more efficient that UIImage with
 the same size is returned.
 @completionBlock: the block to provide image fetcher result.
 */
@optional
- (void)loadImageWithURL:(NSURL*)url
                    size:(CGSize)targetSize
              completion:(LynxImageLoadCompletionBlock)completionBlock
    __attribute__((deprecated("Use loadImageWithURL:size:contextInfo:completion: instead.")));

/*!
 Load image asynchronously.
 @param url: target image url.
 @param targetSize: the target screen size for showing the image. It is more efficient that UIImage
   with the same size is returned.
 @param completionBlock: the block to provide image fetcher result.
 @return: A block which can cancel the image request if it is not finished. nil if cancel action is
   not supported.
*/
@optional
- (dispatch_block_t)cancelableLoadImageWithURL:(NSURL*)url
                                          size:(CGSize)targetSize
                                    completion:(LynxImageLoadCompletionBlock)completionBlock
    __attribute__((deprecated("Use loadImageWithURL:size:contextInfo:completion: instead.")));

#pragma mark - deprecated API
/*!
Deprecated: please use loadResourceWithURL:type:completion from LynxResourceFetcher
Load canvas resource asynchronously
@param ui: ui that fires the request.
@param url: target image url.
@param targetSize: the target screen size for showing the image. It is more efficient that UIImage
with the same size is returned.
@param contextInfo: extra info needed for image request.
@param completionBlock: the block to provide image fetcher result.
@return: A block which can cancel the image request if it is not finished. nil if cancel action is
not supported.
*/
@optional
- (dispatch_block_t)loadCanvasImageWithURL:(NSURL*)url
                               contextInfo:(nullable NSDictionary*)contextInfo
                                completion:(LynxCanvasImageLoadCompletionBlock)completionBlock;

/*!
 Image decoding proxy for Helium.
 @param data: Image file data.
 @return: Image decode result.
*/
@optional
+ (UIImage*)decodeImage:(NSData*)data;

@end

NS_ASSUME_NONNULL_END
