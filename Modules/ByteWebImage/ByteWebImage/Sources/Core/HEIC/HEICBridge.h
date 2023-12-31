//
//  HEICBridge.h
//  ByteWebImage
//
//  Created by Nickyo on 2023/2/15.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HEICBridge : NSObject

- (nullable instancetype)initWithData:(NSData *)data;

- (CFTimeInterval)frameDelayAtIndex:(NSInteger)index;

- (nullable CGImageRef)copyImageAtIndex:(NSInteger)index decodeForDisplay:(BOOL)display cropRect:(CGRect)cropRect downsampleSize:(CGSize)downsampleSize limitSize:(CGFloat)limitSize CF_RETURNS_RETAINED;

- (NSInteger)imageCount;

- (NSInteger)loopCount;

- (CGSize)originSize;

- (CGImagePropertyOrientation)imageOrientation;

@end

NS_ASSUME_NONNULL_END
