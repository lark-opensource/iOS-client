//
// Created by liujianlong on 2022/8/5.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ByteViewVideoRotation) {
    ByteViewVideoRotation_0 = 0,
    ByteViewVideoRotation_90 = 90,
    ByteViewVideoRotation_180 = 180,
    ByteViewVideoRotation_270 = 270,
};

@interface ByteViewVideoFrame : NSObject

- (instancetype)initWithPixelBuffer:(CVPixelBufferRef)buffer
                           cropRect:(CGRect)cropRect
                               flip:(BOOL)flip
                     flipHorizontal:(BOOL)flipHorizontal
                           rotation:(ByteViewVideoRotation)rotation
                        timeStampNs:(int64_t)timeStampNs;

@property(assign, nonatomic, readonly) CVPixelBufferRef pixelBuffer;
@property(assign, nonatomic, readonly) ByteViewVideoRotation rotation;
@property(assign, nonatomic, readonly) int64_t timeStampNs;

@property(assign, nonatomic, readonly) CGSize size;

// unit rect applied before rotation
@property(assign, nonatomic, readonly) CGRect cropRect;

@property(assign, nonatomic, readonly) BOOL flip;

@property(assign, nonatomic, readonly) BOOL flipHorizontal;

@end

NS_ASSUME_NONNULL_END
