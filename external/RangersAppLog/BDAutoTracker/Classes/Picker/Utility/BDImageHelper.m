//
//  BDImageHelper.m
//  Pods-ProjectTest0
//
//  Created by bytedance on 2023/8/30.
//

#import "BDImageHelper.h"

//#if __has_include(<libwebp/encode.h>)
//#import <libwebp/encode.h>
//#else
//#import "encode.h"
//#endif


NSData * bd_picker_bitmap2webp(UIImage *image, CGFloat quality) {
//    CGImageRef webPImageRef = image.CGImage;
//    size_t webPBytesPerRow = CGImageGetBytesPerRow(webPImageRef);
//
//    size_t webPImageWidth = CGImageGetWidth(webPImageRef);
//    size_t webPImageHeight = CGImageGetHeight(webPImageRef);
//
//    CGDataProviderRef webPDataProviderRef = CGImageGetDataProvider(webPImageRef);
//    CFDataRef webPImageDatRef = CGDataProviderCopyData(webPDataProviderRef);
//
//    uint8_t *webPImageData = (uint8_t *)CFDataGetBytePtr(webPImageDatRef);
//
//    WebPConfig config;
//    if (!WebPConfigPreset(&config, WEBP_PRESET_DEFAULT, quality)) {
//        CFRelease(webPImageDatRef);
//        return nil;
//    }
//
//    config.method = 2;
//    config.alpha_compression = 0;
//    config.alpha_filtering = 0;
//    config.alpha_quality = 0;
//
//    if (!WebPValidateConfig(&config)) {
//        CFRelease(webPImageDatRef);
//        return nil;
//    }
//
//    WebPPicture pic;
//    if (!WebPPictureInit(&pic)) {
//        CFRelease(webPImageDatRef);
//        return nil;
//    }
//    pic.width = (int)webPImageWidth;
//    pic.height = (int)webPImageHeight;
//    pic.colorspace = WEBP_YUV420;
//
////    WebPPictureImportRGBA(&pic, webPImageData, (int)webPBytesPerRow);
//    WebPPictureImportBGRA(&pic, webPImageData, (int)webPBytesPerRow);
//
//    WebPPictureARGBToYUVA(&pic, WEBP_YUV420);
//    WebPCleanupTransparentArea(&pic);
//
//    WebPMemoryWriter writer;
//    WebPMemoryWriterInit(&writer);
//    pic.writer = WebPMemoryWrite;
//    pic.custom_ptr = &writer;
//    WebPEncode(&config, &pic);
//
//    NSData *webPFinalData = [NSData dataWithBytes:writer.mem length:writer.size];
//
//    free(writer.mem);
//    WebPPictureFree(&pic);
//    CFRelease(webPImageDatRef);
//
//    return webPFinalData;
    
    return nil;
}
