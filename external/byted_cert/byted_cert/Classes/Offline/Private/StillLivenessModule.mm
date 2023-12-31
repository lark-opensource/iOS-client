//
//  StillLivenessModule.m
//  Pods
#import "StillLivenessModule.h"
#import "FaceLiveUtils.h"
#import "BytedCertDefine.h"

#import "FaceSDK_API.h"
#import "Face_Model.h"

#import "StillLiveness_API.h"
#import "StillLiveness_Model.h"

#import "BytedCertWrapper.h"
#import "BDCTStringConst.h"
#import "BytedCertManager+DownloadPrivate.h"
#import "BDCTAdditions.h"
#import "BytedCertInterface+Logger.h"


@interface StillLivenessModule ()
{
    FaceHandle handle_face;
    StillLivenessHandle handle_still_liveness;
    bool _is_released;
}

@end


@implementation StillLivenessModule

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    _is_released = false;

    NSString *res;
    NSString *modelPath = [BytedCertWrapper sharedInstance].modelPathList[BytedCertParamTargetOffline];
    res = [BytedCertManager getModelByPre:modelPath pre:bdct_offline_model_pre()[0]];
    if (res == nil) {
        res = [[NSBundle bdct_bundle] pathForResource:@MODEL_TT_FACE ofType:nil];
    }
    if (res == nil) {
        res = [FaceLiveUtils getResource:@"face.bundle" resName:@MODEL_TT_FACE];
    }
    [BytedCertInterface logWithInfo:[NSString stringWithFormat:@"byted_cet offline stillliveness face model:%@", res] params:nil];
    NSLog(@"Face model: %@", res);

    const char *model_path = [res UTF8String];
    long long config = TT_MOBILE_DETECT_MODE_IMAGE | TT_INIT_SMALL_MODEL | TT_MOBILE_DETECT_FULL;
    int ret = FS_CreateHandler(config, model_path, &handle_face);
    if (ret != TT_OK) {
        [BytedCertInterface logWithErrorInfo:[NSString stringWithFormat:@"byted_cet offline stillLiveness init fail: creat face handle fail, code:%@", @(ret)] params:nil error:nil];
        NSLog(@"Still liveness Create face error, code: %d", ret);
        return nil;
    }

    ret = StillLiveness_CreateHandle(&handle_still_liveness);
    if (ret != SMASH_OK) {
        [BytedCertInterface logWithErrorInfo:[NSString stringWithFormat:@"byted_cet offline stillLiveness init fail: creat still handle fail, code:%@", @(ret)] params:nil error:nil];
        NSLog(@"Still liveness Create still error, code: %d", ret);
        return nil;
    }

    NSString *res2 = [BytedCertManager getModelByPre:modelPath pre:bdct_offline_model_pre()[2]];
    if (res2 == nil) {
        res2 = [[NSBundle bdct_bundle] pathForResource:@MODEL_TT_STILLLIVENESS_MASK ofType:nil];
    }
    if (res2 == nil) {
        res2 = [FaceLiveUtils getResource:@"still_liveness.bundle" resName:@MODEL_TT_STILLLIVENESS_MASK];
    }
    NSLog(@"StillLiveness model: %@", res2);
    [BytedCertInterface logWithInfo:[NSString stringWithFormat:@"byted_cet offline StillLiveness model:%@", res2] params:nil];
    if (res2 == nil) {
        return nil;
    }
    const char *model_path2 = [res2 UTF8String];
    ret = StillLiveness_LoadModel(handle_still_liveness, kStillLivenessModel1, model_path2);
    if (ret != TT_OK) {
        [BytedCertInterface logWithErrorInfo:[NSString stringWithFormat:@"byted_cet offline stillLiveness init fail: load still model fail, code:%@", @(ret)] params:nil error:nil];
        NSLog(@"StillLiveness LoadModel error, code: %d", ret);
        return nil;
    }


    return self;
}

- (void)dealloc {
    NSLog(@"FaceVerifyModule dealloc.\n");
    if (!_is_released) {
        StillLiveness_ReleaseHandle(handle_still_liveness);
        FS_ReleaseHandle(handle_face);
        _is_released = true;
    }
}

- (int)doFaceLive:(NSData *)faceData {
    UIImage *image = [UIImage imageWithData:faceData];
    int width = CGImageGetWidth(image.CGImage);
    int height = CGImageGetHeight(image.CGImage);
    unsigned char *baseAddress = [self pixelBRGABytesFromImage:image];
    int stride = width * 4;

    AIFaceInfo face_result_;
    StillLivenessArgs args;
    StillLivenessRet SLResult;

    int status = FS_DoPredict(handle_face,
                              baseAddress,
                              kPixelFormat_BGRA8888,
                              (int)width,
                              (int)height,
                              (int)stride,
                              kClockwiseRotate_0,
                              TT_MOBILE_DETECT_MODE_IMAGE | TT_MOBILE_DETECT_FULL,
                              &face_result_);
    if (status != TT_OK) {
        NSLog(@"Still liveness err, status: %d\n", status);
        return status;
    }
    args.base.image = baseAddress;
    args.base.image_height = height;
    args.base.image_width = width;
    args.base.image_stride = stride;
    args.base.orient = kClockwiseRotate_0;
    args.base.pixel_fmt = kPixelFormat_BGRA8888;
    args.faces_info = &face_result_;
    status = StillLiveness_DO(handle_still_liveness, &args, &SLResult);

    if (status != TT_OK) {
        NSLog(@"Still liveness err, status: %d\n", status);
        return status;
    }

    int flag = SLResult.flag;
    if (flag < 2) {
        return 0;
    } else {
        return flag;
    }
}

- (unsigned char *)pixelBRGABytesFromImage:(UIImage *)image {
    return [self pixelBRGABytesFromImageRef:image.CGImage];
}

- (unsigned char *)pixelBRGABytesFromImageRef:(CGImageRef)imageRef {
    NSUInteger iWidth = CGImageGetWidth(imageRef);
    NSUInteger iHeight = CGImageGetHeight(imageRef);
    NSUInteger iBytesPerPixel = 4;
    NSUInteger iBytesPerRow = iBytesPerPixel * iWidth;
    NSUInteger iBitsPerComponent = 8;
    unsigned char *imageBytes = (unsigned char *)malloc(iWidth * iHeight * iBytesPerPixel);

    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();

    CGContextRef context = CGBitmapContextCreate(imageBytes,
                                                 iWidth,
                                                 iHeight,
                                                 iBitsPerComponent,
                                                 iBytesPerRow,
                                                 colorspace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);

    CGRect rect = CGRectMake(0, 0, iWidth, iHeight);
    CGContextDrawImage(context, rect, imageRef);
    CGColorSpaceRelease(colorspace);
    CGContextRelease(context);
    //    CGImageRelease(imageRef);

    return imageBytes;
}


@end
