// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxImageLoader.h"
#import "LynxDebugger.h"
#import "LynxEnv.h"
#import "LynxImageProcessor.h"
#import "LynxLog.h"
#import "LynxNinePatchImageProcessor.h"
#import "LynxTraceEvent.h"
#import "LynxUI.h"

NSString* const LynxImageFetcherContextKeyUI = @"LynxImageFetcherContextKeyUI";
NSString* const LynxImageFetcherContextKeyLynxView = @"LynxImageFetcherContextKeyLynxView";
NSString* const LynxImageFetcherContextKeyDownsampling = @"LynxImageFetcherContextKeyDownsampling";
NSString* const LynxImageRequestOptions = @"LynxImageRequestOptions";
BOOL LynxImageFetchherSupportsProcessor(id<LynxImageFetcher> fetcher) {
  return [fetcher respondsToSelector:@selector(loadImageWithURL:
                                                     processors:size:contextInfo:completion:)];
}
@implementation LynxImageLoader
+ (nonnull instancetype)sharedInstance {
  static dispatch_once_t once;
  static id instance;
  dispatch_once(&once, ^{
    instance = [self new];
  });
  return instance;
}

- (dispatch_block_t)loadImageFromURL:(NSURL*)url
                                size:(CGSize)targetSize
                         contextInfo:(NSDictionary*)contextInfo
                          processors:(NSArray*)processors
                        imageFetcher:(id<LynxImageFetcher>)imageFetcher
                           completed:(LynxImageLoadCompletionBlock)completed {
  BOOL supportsProcessor = LynxImageFetchherSupportsProcessor(imageFetcher);
  LynxImageLoadCompletionBlock recordBlock = ^(UIImage* _Nullable image, NSError* _Nullable error,
                                               NSURL* _Nullable imageURL) {
    if (error == nil && image != nil && [[LynxEnv sharedInstance] recordEnable]) {
      [LynxDebugger recordResource:UIImagePNGRepresentation(image) withKey:imageURL.absoluteString];
    }
    completed(image, error, url);
  };
  if (supportsProcessor) {
    return [imageFetcher loadImageWithURL:url
                               processors:processors
                                     size:targetSize
                              contextInfo:contextInfo
                               completion:^(UIImage* _Nullable image, NSError* _Nullable error,
                                            NSURL* _Nullable imageURL) {
                                 recordBlock(image, error, url);
                               }];
  }
  LynxImageLoadCompletionBlock completionBlock =
      ^(UIImage* _Nullable image, NSError* _Nullable error, NSURL* _Nullable imageURL) {
        if (error != nil) {
          LLogError(@"loadImageFromURL failed url:%@,%@", url, [error localizedDescription]);
        }
        // If there no processor, return image now
        if (!processors || processors.count == 0) {
          recordBlock(image, error, url);
          return;
        }
        NSMutableArray* syncProcessors = [NSMutableArray array];
        NSMutableArray* asyncProcessors = [NSMutableArray array];
        for (id<LynxImageProcessor> processor in processors) {
          if ([processor isKindOfClass:[LynxNinePatchImageProcessor class]]) {
            [syncProcessors addObject:processor];
          } else {
            [asyncProcessors addObject:processor];
          }
        }
        UIImage* syncFilterImage = image;
        // Deal with sync processors
        for (id<LynxImageProcessor> processor in syncProcessors) {
          syncFilterImage = [processor processImage:syncFilterImage];
        }
        // If there no asyncProcessor, return image now
        if (asyncProcessors.count == 0) {
          recordBlock(syncFilterImage, error, url);
          return;
        }
        // Deal with async processors
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          UIImage* asyncFilterImage = syncFilterImage;
          for (id<LynxImageProcessor> processor in asyncProcessors) {
            asyncFilterImage = [processor processImage:asyncFilterImage];
          }
          // Return baked image to main thread
          dispatch_async(dispatch_get_main_queue(), ^{
            recordBlock(asyncFilterImage, error, url);
          });
        });
      };
  if ([imageFetcher respondsToSelector:@selector(loadImageWithURL:size:contextInfo:completion:)]) {
    LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxImageFetcher loadImageWithURL");
    [imageFetcher loadImageWithURL:url
                              size:targetSize
                       contextInfo:contextInfo
                        completion:completionBlock];
    LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER);
  } else if ([imageFetcher respondsToSelector:@selector(cancelableLoadImageWithURL:
                                                                              size:completion:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [imageFetcher cancelableLoadImageWithURL:url size:targetSize completion:completionBlock];
  } else if ([imageFetcher respondsToSelector:@selector(loadImageWithURL:size:completion:)]) {
    [imageFetcher loadImageWithURL:url size:targetSize completion:completionBlock];
#pragma clang diagnostic pop
  }
  return nil;
}

- (dispatch_block_t)loadCanvasImageFromURL:(NSURL*)url
                               contextInfo:(NSDictionary*)contextInfo
                                processors:(NSArray*)processors
                              imageFetcher:(id<LynxImageFetcher>)imageFetcher
                                 completed:(LynxCanvasImageLoadCompletionBlock)completed {
  LLogInfo(@"loadCanvasImageFromURL url:%@", url);
  LynxCanvasImageLoadCompletionBlock completionBlock =
      ^(NSData* _Nullable image, NSError* _Nullable error, NSURL* _Nullable imageURL) {
        if (error != nil) {
          LLogError(@"loadImageFromURL failed url:%@,%@", url, [error description]);
        }
        // If there no processor, return image now
        if (!processors || processors.count == 0) {
          if (error == nil && image != nil && [[LynxEnv sharedInstance] recordEnable]) {
            [LynxDebugger recordResource:image withKey:imageURL.absoluteString];
          }
          completed(image, error, url);
          return;
        }
      };
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  if ([imageFetcher respondsToSelector:@selector(loadCanvasImageWithURL:contextInfo:completion:)]) {
    LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxImageFetcher loadCanvasImageWithURL");
    [imageFetcher loadCanvasImageWithURL:url contextInfo:contextInfo completion:completionBlock];
    LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER);
  } else {
    LLogError(@"No implement for loadCanvasImageWithURL:contextInfo:completion in imageFetcher");
    NSError* error = [NSError
        errorWithDomain:
            @"No implement for loadCanvasImageWithURL:contextInfo:completion in imageFetcher"
                   code:-1
               userInfo:nil];
    if (completionBlock) {
      completionBlock(nil, error, url);
    }
  }
#pragma clang diagnostic pop
  return nil;
}

@end
