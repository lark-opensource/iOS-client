//
//  WebpBridge.h
//  ByteWebImage
//
//  Created by xiongmin on 2021/5/10.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WebpBridge : NSObject

- (instancetype)initWithContentOfFile:(NSString *)file;

- (nullable instancetype)initWithData:(NSData *)data;

- (CFTimeInterval)frameDelayAtIndex:(NSUInteger)index;

- (nullable CGImageRef)copyImageAtIndex:(NSUInteger)index decodeForDisplay:(BOOL)display cropRect:(CGRect)cropRect downsampleSize:(CGSize)downsampleSize gifLimitSize:(CGFloat)gifLimit;

- (instancetype)initWithIncrementalData:(NSData *)data;

- (void)changeDecoderWithData:(NSData *)data finished:(BOOL)finished;

- (BOOL)progressiveDownloading;

- (NSUInteger)imageCount;

- (NSUInteger)loopCount;

- (CGSize)canvasSize;

- (CGSize)originSize;

- (UIImageOrientation)imageOrientation;

- (BOOL)hasDownsample;

- (BOOL)didScaleDown;

- (BOOL)hasCrop;

+ (BOOL)isAnimatedImage:(NSData *)data;

+ (NSInteger)imageCount:(NSData *)data;

+ (BOOL)supportProgressDecode:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
