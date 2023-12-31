//
//  BDWebImageSRErrorDomain.h
//  BDWebImage
//
//  Created by Bytedance on 2021/4/29.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SuperResolutionErrorType) {
    SRErrorTypeEmulatorNotSupported = 0,          ///< 0-not arm64
    SRErrorTypeImageTooLarge,                     ///< 1-image is too large
    SRErrorTypeMemoryNotEnough,                   ///< 2-memory not enough
    SRErrorTypeCoreFailed,                        ///< 3-internal error
    SRErrorTypeAnimatedImageNotSupported,         ///< 4-not support animated image
    SRErrorTypeImageCreationFailed,               ///< 5-sr successed, failed in image creation
    SRErrorTypeNotDivisibleByFour                 ///< 6-the width and height are not divisible by 4
};

