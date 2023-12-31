//
//  BDImageDecoderImageIO.h
//  BDWebImage
//
//  Created by lizhuoli on 2017/12/13.
//

#import "BDImageDecoder.h"
#import <ImageIO/ImageIO.h>

@interface BDImageDecoderImageIO : NSObject<BDImageDecoder>

- (instancetype)initWithImageSource:(CGImageSourceRef)imageSource;

@end
