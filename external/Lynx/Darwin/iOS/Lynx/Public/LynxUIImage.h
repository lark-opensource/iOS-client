// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxConverter.h"
#import "LynxError.h"
#import "LynxShadowNode.h"
#import "LynxUI.h"

NS_ASSUME_NONNULL_BEGIN

@class BDWebImageRequest;

typedef NS_ENUM(NSInteger, LynxImageRequestType) {
  LynxImageRequestUndefined,
  LynxImageRequestSrc,
  LynxImageRequestPlaceholder,
};

typedef NS_OPTIONS(NSInteger, LynxRequestOptions) {
  LynxImageDefaultOptions = 0,
  LynxImageIgnoreMemoryCache = 1 << 1,  // don't search memory cache
  LynxImageIgnoreDiskCache = 1 << 2,    // don't search disk cache
  LynxImageNotCacheToMemory = 1 << 3,   // don't store to memory cache
  LynxImageNotCacheToDisk = 1 << 4,     // don't store to disk cache
  LynxImageIgnoreCDNDowngradeCachePolicy =
      1 << 5,  // if not set, the CDN downgraded image will not store to disk cache
};

@interface LynxURL : NSObject

@property(nonatomic) NSURL* url;
@property(nonatomic) NSURL* redirectedURL;
@property(nonatomic) BOOL initiallyLoaded;
@property(nonatomic) LynxImageRequestType type;
@property(nonatomic) NSURL* preUrl;

// Image status info
@property(nonatomic) NSTimeInterval fetchTime;
@property(nonatomic) NSTimeInterval completeTime;
@property(nonatomic) CGFloat memoryCost;
@property(nonatomic) NSInteger isSuccess;
@property(nonatomic) NSError* error;

@property(nonatomic) NSMutableDictionary* resourceInfo;

- (void)updatePreviousUrl;
- (BOOL)isPreviousUrl;
@end  // LynxURL

@interface LynxUIImage : LynxUI <UIImageView*>

@property(nonatomic, readonly, getter=isAnimated) BOOL animated;
@property(nonatomic, strong, nullable) BDWebImageRequest* customImageRequest;
@property(nonatomic) NSMutableDictionary* resLoaderInfo;
@property(nonatomic, readonly) LynxRequestOptions requestOptions;

- (void)startAnimating;
- (bool)getEnableImageDownsampling;

@end

@interface LynxConverter (UIViewContentMode)

@end

@interface LynxImageShadowNode : LynxShadowNode

@end

NS_ASSUME_NONNULL_END
