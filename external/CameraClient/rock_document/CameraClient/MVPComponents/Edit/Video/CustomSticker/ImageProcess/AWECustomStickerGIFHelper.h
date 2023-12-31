//
//  AWECustomStickerGIFHelper.h
//  CameraClient
//
//  Created by 卜旭阳 on 2020/6/28.
//

#import <Foundation/Foundation.h>

@interface AWECustomStickerGIFHelper : NSObject

+ (NSData *)compressGIFData:(NSData *)gifData withCompressRatio:(CGFloat)compressRatio;

@end
