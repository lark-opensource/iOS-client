//
// Created by liujianlong on 2022/8/5.
//

#import "ByteViewVideoFrame.h"


@implementation ByteViewVideoFrame

- (instancetype)initWithPixelBuffer:(CVPixelBufferRef)buffer
                           cropRect:(CGRect)cropRect
                               flip:(BOOL)flip
                     flipHorizontal:(BOOL)flipHorizontal
                           rotation:(ByteViewVideoRotation)rotation
                        timeStampNs:(int64_t)timeStampNs {
    if (self = [super init]) {
        CVBufferRetain(buffer);
        _pixelBuffer = buffer;
        _cropRect = cropRect;
        _flip = flip;
        _flipHorizontal = flipHorizontal;
        _rotation = rotation;
        _timeStampNs = timeStampNs;
    }
    return self;
}

- (CGSize)size {
    size_t originWidth = CVPixelBufferGetWidth(_pixelBuffer);
    size_t originHeight = CVPixelBufferGetHeight(_pixelBuffer);
    if (_rotation == ByteViewVideoRotation_0 || _rotation == ByteViewVideoRotation_180) {
        return CGSizeMake(originWidth * _cropRect.size.width, originHeight * _cropRect.size.height);
    } else {
        return CGSizeMake(originHeight * _cropRect.size.height, originWidth * _cropRect.size.width);
    }
}

- (void)dealloc {
    CVBufferRelease(_pixelBuffer);
}

@end
