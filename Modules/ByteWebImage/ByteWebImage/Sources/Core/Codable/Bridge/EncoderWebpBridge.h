//
//  EncoderWebpBridge.h
//  ByteWebImage
//
//  Created by kangsiwan on 2022/5/9.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface EncoderWebpBridge : NSObject

+ (NSData * _Nullable)encodeWithImageRef:(CGImageRef)imageRef quality:(float)quality;

@end

NS_ASSUME_NONNULL_END
