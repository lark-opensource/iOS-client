//
//  QRCodeDecoder.m
//  LarkWeb
//
//  Created by CharlieSu on 2018/11/26.
//

#import "QRCodeDecoder.h"
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <smash/Enigma_API.h>
#import <smash/tt_common.h>

@implementation QRCodeScanResult {
}
@end

@interface QRCodeDecoder () {
    EnigmaHandle handle;
    EnigmaResult* enigma_res;
}

@end

@implementation QRCodeDecoder

- (instancetype)init {
    return [self initWithType:QRCodeDecoderTypeQR];
}

- (instancetype)initWithType:(QRCodeDecoderType)type {
    self = [super init];
    if (!self) {
        return nil;
    }

    int ret = Enigma_CreateHandle(&handle);
    if (ret != 0) {
        return nil;
    }
    if (type & QRCodeDecoderTypeQR) {
        Enigma_SetDecodeHint(handle, EnigmaParamType::CodeType, CODE_TYPE_QRCODE);
    }
    if (type & QRCodeDecoderTypeBar) {
        Enigma_SetDecodeHint(handle, EnigmaParamType::CodeType, CODE_TYPE_EAN_13_CODE);
        Enigma_SetDecodeHint(handle, EnigmaParamType::CodeType, CODE_TYPE_UPC_A_CODE);
        Enigma_SetDecodeHint(handle, EnigmaParamType::CodeType, CODE_TYPE_UPC_E_CODE);
        Enigma_SetDecodeHint(handle, EnigmaParamType::CodeType, CODE_TYPE_EAN_8_CODE);
        Enigma_SetDecodeHint(handle, EnigmaParamType::CodeType, CODE_TYPE_CODE39_CODE);
        Enigma_SetDecodeHint(handle, EnigmaParamType::CodeType, CODE_TYPE_CODE128_CODE);
    }
    if (type & QRCodeDecoderTypeImage) {
        Enigma_SetDecodeHint(handle, EnigmaParamType::ScanType, 1);
    }

    Enigma_SetDecodeHint(handle, EnigmaParamType::AutoZoomIn, 1);
    enigma_res = nil;
    return self;
}

- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image
{
    NSDictionary *options = @{
                              (NSString*)kCVPixelBufferCGImageCompatibilityKey : @YES,
                              (NSString*)kCVPixelBufferCGBitmapContextCompatibilityKey : @YES,
                              (NSString*)kCVPixelBufferIOSurfacePropertiesKey: [NSDictionary dictionary]
                              };
    CVPixelBufferRef pxbuffer = NULL;

    CGFloat frameWidth = CGImageGetWidth(image);
    CGFloat frameHeight = CGImageGetHeight(image);

    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameWidth,
                                          frameHeight,
                                          kCVPixelFormatType_32BGRA,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);

    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);

    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();

    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 frameWidth,
                                                 frameHeight,
                                                 8,
                                                 CVPixelBufferGetBytesPerRow(pxbuffer),
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0,
                                           0,
                                           frameWidth,
                                           frameHeight),
                       image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);

    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);

    return pxbuffer;
}


- (nonnull QRCodeScanResult*)scanImage: (nonnull UIImage*)image {
    CVPixelBufferRef pixelBuffer = [self pixelBufferFromCGImage: ([image CGImage])];
    return [self scanPixelBuffer:pixelBuffer format:kPixelFormat_BGRA8888];
}

- (nonnull QRCodeScanResult*)scanVideoPixelBuffer: (nullable CVPixelBufferRef)pixelBuffer {
    return [self scanPixelBuffer:pixelBuffer format:kPixelFormat_NV12];
}

- (nonnull QRCodeScanResult*)scanPixelBuffer: (nullable CVPixelBufferRef)pixelBuffer format:(PixelFormatType)format {
    QRCodeScanResult* result = [[QRCodeScanResult alloc] init];

    @try {
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        void *baseaddress = NULL;
        baseaddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);

        unsigned long height = CVPixelBufferGetHeight(pixelBuffer);
        unsigned long width = CVPixelBufferGetWidth(pixelBuffer);
        unsigned long stride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);

        int ret = Enigma_Decode(handle,
                                (unsigned char*)baseaddress,
                                format,
                                (int) width,
                                (int) height,
                                (int) stride,
                                0,
                                0,
                                (int) width,
                                (int) height,
                                kClockwiseRotate_0,
                                &enigma_res);
        if (ret != 0 || enigma_res == nil) {
            result.type = QRCodeScanResultTypeNotFound;
            CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
            return result;
        }
        if (enigma_res && enigma_res->code_count == 0) {
            result.type = QRCodeScanResultTypeZoom;
            result.resizeFactor = [[NSNumber alloc] initWithFloat:enigma_res->zoom_in_factor];
            CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
            return result;
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    } @catch (NSException *exception) {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        result.type = QRCodeScanResultTypeNotFound;
        return result;
    }

    @try {
        result.type = QRCodeScanResultTypeFound;
        result.code = [NSString stringWithCString:enigma_res->code[0].text encoding:NSUTF8StringEncoding];
        return result;
    } @catch (NSException *exception) {
        result.type = QRCodeScanResultTypeNotFound;
        return result;
    }
}

- (void)dealloc {
    Enigma_Release(handle);
}

@end
