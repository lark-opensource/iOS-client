//
//  BDPImageHelper.h
//  Timor
//
//  Created by 刘相鑫 on 2018/12/10.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, BDPImageFormat) {
    BDPImageFormatUnkonw = 0,
    BDPImageFormatJPEG = 1,
    BDPImageFormatPNG = 2,
    BDPImageFormatGIF = 3,
    BDPImageFormatTIFF = 4,
    BDPImageFormatWebP = 5,
    BDPImageFormatBMP = 6,
    BDPImageFormatPSD = 7,
    BDPImageFormatIFF = 8,
    BDPImageFormatICO = 9, //vnd.microsoft.icon
    BDPImageFormatJP2 = 10
};


NS_ASSUME_NONNULL_BEGIN

@interface BDPImageHelper : NSObject

/*------------------------------------------------------*/
//                  根据ImageData获取图片的类型字符串
//                     返回NSString *
/*------------------------------------------------------*/
+ (nullable NSString *)mimeTypeForImageData:(NSData *)data;

/*------------------------------------------------------*/
//                  根据ImageData获取图片的类型
//                     返回BDPImageFormat
/*------------------------------------------------------*/
+ (BDPImageFormat)contentFormatForImageData:(NSData *)imageData;

/**
 获取图片类型字符串

 @param format 图片类型
 @return 图片类型字符串
 */
+ (nullable NSString *)mimeTypeForBDPImageFormat:(BDPImageFormat)format;

@end

NS_ASSUME_NONNULL_END
