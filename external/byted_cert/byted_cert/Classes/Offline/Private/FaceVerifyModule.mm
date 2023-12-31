//
//  FaceVerifyModule.m

#import "FaceVerifyModule.h"

#import "FaceLiveUtils.h"

#import <UIKit/UIKit.h>

#import "FaceSDK_API.h"
#import "Face_Model.h"
#import "FaceVerifySDK_API.h"
#import "FaceVerify_Model.h"
#import "BytedCertWrapper.h"
#import "BDCTStringConst.h"
#import "BytedCertDefine.h"
#import "BDCTAdditions.h"
#import "BytedCertManager+DownloadPrivate.h"
#import "BytedCertInterface+Logger.h"

#import <vector>


@interface FaceVerifyModule ()
{
    FaceHandle handle_face;
    FaceVerifyHandle handle_verify;
    bool _is_released;
}

@end


@implementation FaceVerifyModule

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    _is_released = false;

    //get model path
    NSString *modelPath = [BytedCertWrapper sharedInstance].modelPathList[BytedCertParamTargetOffline];
    NSString *res = [BytedCertManager getModelByPre:modelPath pre:bdct_offline_model_pre()[0]];
    if (res == nil) {
        res = [[NSBundle bdct_bundle] pathForResource:@MODEL_TT_FACE ofType:nil];
    }
    if (res == nil) {
        res = [FaceLiveUtils getResource:@"face.bundle" resName:@MODEL_TT_FACE];
    }
    [BytedCertInterface logWithInfo:[NSString stringWithFormat:@"byted_cet offline faceverify face model:%@", res] params:nil];
    NSLog(@"Face model: %@", res);
    if (res == nil) {
        return nil;
    }
    const char *model_path = [res UTF8String];
    long long config = TT_MOBILE_DETECT_MODE_IMAGE | TT_INIT_SMALL_MODEL | TT_MOBILE_DETECT_FULL;
    int ret = FS_CreateHandler(config, model_path, &handle_face);
    if (ret != TT_OK) {
        [BytedCertInterface logWithErrorInfo:[NSString stringWithFormat:@"byted_cet offline faceverify init fail: creat face handle fail, code:%@", @(ret)] params:nil error:nil];
        NSLog(@"FaceVerify Create Face error, code: %d", ret);
        return nil;
    }


    NSString *res2 = [BytedCertManager getModelByPre:modelPath pre:bdct_offline_model_pre()[1]];
    if (res2 == nil) {
        res2 = [[NSBundle bdct_bundle] pathForResource:@MODEL_TT_FACEVERIFY ofType:nil];
    }
    if (res2 == nil) {
        res2 = [FaceLiveUtils getResource:@"faceverify.bundle" resName:@MODEL_TT_FACEVERIFY];
    }
    NSLog(@"FaceVerify model: %@", res2);
    [BytedCertInterface logWithInfo:[NSString stringWithFormat:@"byted_cet offline faceverify model:%@", res2] params:nil];
    if (res2 == nil) {
        return nil;
    }
    const char *model_path2 = [res2 UTF8String];
    ret = FVS_CreateHandler(model_path2, 10, &handle_verify);
    if (ret != TT_OK) {
        [BytedCertInterface logWithErrorInfo:[NSString stringWithFormat:@"byted_cet offline faceverify init fail: creat faceverify handle fail, code:%@", @(ret)] params:nil error:nil];
        NSLog(@"FaceVerify Create verify error, code: %d", ret);
        return nil;
    }

    return self;
}

- (void)dealloc {
    NSLog(@"FaceVerifyModule dealloc.\n");
    if (!_is_released) {
        FVS_ReleaseHandle(handle_verify);
        FS_ReleaseHandle(handle_face);
        _is_released = true;
    }
}

- (int)verify:(NSData *)faceData
     oriPhoto:(NSData *)oriData {
    UIImage *image = [UIImage imageWithData:faceData];
    int width = CGImageGetWidth(image.CGImage);
    int height = CGImageGetHeight(image.CGImage);
    unsigned char *baseAddress = [self pixelBRGABytesFromImage:image];
    int stride = width * 4;

    AIFaceInfo face_result_;
    AIFaceVerifyInfo face_verify_result_;

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
        NSLog(@"Verify FS_DoPredict err, status: %d\n", status);
        return status;
    }
    status = FVS_DoExtractFeature(handle_verify,
                                  baseAddress,
                                  kPixelFormat_BGRA8888,
                                  (int)width,
                                  (int)height,
                                  (int)stride,
                                  kClockwiseRotate_0,
                                  &face_result_,
                                  &face_verify_result_);
    if (status != TT_OK) {
        NSLog(@"Verify FVS_DoExtractFeature err, status: %d\n", status);
        return status;
    }

    std::vector<float> feature1(face_verify_result_.features[0], face_verify_result_.features[0] + AI_FACE_FEATURE_DIM);

    image = [UIImage imageWithData:oriData];
    width = CGImageGetWidth(image.CGImage);
    height = CGImageGetHeight(image.CGImage);
    baseAddress = [self pixelBRGABytesFromImage:image];
    stride = width * 4;

    status = FS_DoPredict(handle_face,
                          baseAddress,
                          kPixelFormat_BGRA8888,
                          (int)width,
                          (int)height,
                          (int)stride,
                          kClockwiseRotate_0,
                          TT_MOBILE_DETECT_MODE_IMAGE | TT_MOBILE_DETECT_FULL,
                          &face_result_);
    if (status != TT_OK) {
        NSLog(@"Verify ori FS_DoPredict err, status: %d\n", status);
        return status;
    }
    if (face_result_.face_count <= 0) {
        NSLog(@"no face count in ori data\n");
        return 1;
    }

    status = FVS_DoExtractFeature(handle_verify,
                                  baseAddress,
                                  kPixelFormat_BGRA8888,
                                  (int)width,
                                  (int)height,
                                  (int)stride,
                                  kClockwiseRotate_0,
                                  &face_result_,
                                  &face_verify_result_);
    if (status != TT_OK) {
        NSLog(@"Verify ori FVS_DoExtractFeature err, status: %d\n", status);
        return status;
    }
    int face_num = face_verify_result_.valid_face_num;
    if (face_num <= 0) {
        NSLog(@"no face feature in ori data\n");
        return 1;
    }
    float *faceFeature = findMaxFace(face_verify_result_);
    std::vector<float> feature2(faceFeature, faceFeature + AI_FACE_FEATURE_DIM);


    std::vector<float> feature1_norm;
    L2Norm(feature1, feature1_norm);
    std::vector<float> feature2_norm;
    L2Norm(feature2, feature2_norm);

    double THRESH = 1.0;
    double dist = L2Dist(feature1_norm, feature2_norm);
    NSLog(@"dist = %.2f\n", dist);
    if (dist < THRESH) {
        return 0;
    } else {
        return 1;
    }
}

float *findMaxFace(AIFaceVerifyInfo &faceVerifyInfo) {
    int maxArea = 0;
    int maxId = 0;
    for (int i = 0; i < faceVerifyInfo.valid_face_num; i++) {
        AIRect box = faceVerifyInfo.base_infos[i].rect;
        int height = box.bottom - box.top;
        int width = box.right - box.left;
        int area = height * width;
        if (area > maxArea) {
            maxArea = area;
            maxId = i;
        }
    }
    return faceVerifyInfo.features[maxId];
}


void L2Norm(const std::vector<float> &feature, std::vector<float> &norm_feature) {
    size_t size = feature.size();
    double sum = 0.0;
    for (auto v : feature) {
        sum += v * v;
    }
    double norm = sqrt(sum);

    norm_feature.resize(size);
    for (size_t i = 0; i < size; ++i) {
        norm_feature[i] = feature[i] / norm;
    }
}

double L2Dist(const std::vector<float> &feature1, const std::vector<float> &feature2) {
    if (feature1.size() != feature2.size()) {
        return -1.0;
    }

    size_t size = feature1.size();
    double sum = 0.0;
    for (size_t i = 0; i < size; ++i) {
        double dist = feature1[i] - feature2[i];
        sum += dist * dist;
    }
    return sqrt(sum);
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
