//
//  ReflectionLiveness.m
//  Pods
//
//  Created by zhengyanxin on 2020/12/18.
//

#import "ReflectionLivenessModule.h"
#import "ReflectionLiveness_API.h"
#import "ReflectionLiveness_Model.h"
#import "FaceLiveUtils.h"
#import "BDCTStringConst.h"
#import "BytedCertDefine.h"
#import "BDCTLog.h"
#import "BDCTAdditions.h"
#import "BytedCertWrapper.h"
#import "BytedCertManager+DownloadPrivate.h"

#import <string>


@interface ReflectionLiveness ()
{
    ReflectionLivenessHandle _handle;
    bool _is_released;
    bool _is_image_saved;
    ReflectionLiveInfo _info_ret;
}

@end


@implementation ReflectionLiveness

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    int ret = ReflectionLiveness_CreateHandle(&_handle);
    if (ret != SMASH_OK) {
        NSLog(@"ReflectionLiveModule Create error, code: %d", ret);
        _algoErrorCode = ret;
        return nil;
    }

    NSString *res;
    NSString *modelPath = [BytedCertWrapper sharedInstance].modelPathList[BytedCertParamTargetReflection];
    res = [BytedCertManager getModelByPre:modelPath pre:bdct_reflection_model_pre()[1]];
    if (res == nil)
        res = [[NSBundle bdct_bundle] pathForResource:@"tt_liveness_v7.1.model" ofType:nil];
    if (res == nil) {
        res = [FaceLiveUtils getResource:@"reflection_liveness.bundle" resName:@"tt_liveness_v7.1.model"];
    }
    NSLog(@"ReflectionLiveModule model: %@", res);
    if (res == nil) {
        _algoErrorCode = -1;
        return nil;
    }
    const char *model_path = [res UTF8String];
    ret = ReflectionLiveness_LoadModel(_handle, LivenessConditionModel, model_path);
    if (ret != SMASH_OK) {
        NSLog(@"ReflectionLiveModule Create error, code: %d", ret);
        _algoErrorCode = ret;
        return nil;
    }

    res = [BytedCertManager getModelByPre:modelPath pre:bdct_reflection_model_pre()[0]];
    if (res == nil)
        res = [[NSBundle bdct_bundle] pathForResource:@"tt_reflection_v1.3.model" ofType:nil];
    if (res == nil) {
        res = [FaceLiveUtils getResource:@"reflection_liveness.bundle" resName:@"tt_reflection_v1.3.model"];
    }
    NSLog(@"ReflectionLiveModule model: %@", res);
    if (res == nil) {
        _algoErrorCode = -1;
        return nil;
    }
    const char *model_path2 = [res UTF8String];
    ret = ReflectionLiveness_LoadModel(_handle, ReflectionLivenessModel, model_path2);
    if (ret != SMASH_OK) {
        NSLog(@"ReflectionLiveModule Create error, code: %d", ret);
        _algoErrorCode = ret;
        return nil;
    }

    //todo set radio

    return self;
}

- (int)setParamsGeneral:(int)type value:(float)value {
    int ret = ReflectionLiveness_SetParamF(_handle, (ReflectionLivenessParamType)type, (void *)(&value));
    if (ret != SMASH_OK) {
        self.algoErrorCode = ret;
        BDCTLogInfo(@"ret code: %d\n", ret);
        return -1;
    }
    return 0;
}

- (CGImageRef)doFaceLive:(CVPixelBufferRef)pixelBuffer
                  orient:(ScreenOrient)orient
                     ret:(ReflectionLiveInfo *)ret {
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);

    OSType format = CVPixelBufferGetPixelFormatType(pixelBuffer);
    unsigned char *baseAddress = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    unsigned long height = CVPixelBufferGetHeight(pixelBuffer);
    unsigned long stride = CVPixelBufferGetBytesPerRow(pixelBuffer);
    unsigned long width = CVPixelBufferGetWidth(pixelBuffer);

    if (format == kCVPixelFormatType_32BGRA) {
        ReflectionLivenessArgs arg;
        ReflectionLivenessRet output;

        arg.base.image = baseAddress;
        arg.base.image_height = (int)height;
        arg.base.image_width = (int)width;
        arg.base.image_stride = (int)stride;
        arg.base.pixel_fmt = kPixelFormat_BGRA8888;
        arg.base.orient = orient;

        int status = ReflectionLiveness_DO(_handle, &arg, &output);
        if (status != SMASH_OK) {
            NSLog(@"LivenessPredict err, status: %d\n", status);
        }

        ret->status = output.prompt_info - 100;
        ret->state_machine_stage = output.current_stage;
        ret->light = output.nxt_light;
        ret->process = output.frame_cnt / (float)output.total_frame;
        ret->detect_result_code = output.detect_result_code;
        //        if (output.detect_result_code == RL_RESULT_REAL && !_is_image_saved) {
        //            [self saveBestImag];
        //            _is_image_saved = true;
        //        }
    }

    return nil;
}

- (int)reStart:(int)type {
    ReflectionLivenessParamType param = (ReflectionLivenessParamType)type;
    int reset = 1;
    return ReflectionLiveness_SetParamF(_handle, param, (void *)(&reset));
}

- (int)saveInfo {
    ReflectionLivenessImageData env, face;

    // RGBA
    ReflectionLiveness_GetBestFrame(_handle, &env, &face);

    if (env.image != nullptr && face.image != nullptr) {
        self.faceImageData = [FaceLiveUtils convertRawBufferToImage:face.image imageName:@"face.jpg" cols:face.image_width rows:face.image_height saveImage:false];
        self.faceWithEnvImageData = [FaceLiveUtils convertRawBufferToImage:env.image imageName:@"env.jpg" cols:env.image_width rows:env.image_height saveImage:false];
    }

    ReflectionLivenessLog liveLog;
    ReflectionLiveness_GetFramesLog(_handle, &liveLog);

    NSMutableString *dataStr = [[NSMutableString alloc] init];

    if (liveLog.frames[0].image == nullptr) {
        [dataStr appendString:[NSString stringWithFormat:@"{\"log\":\"%s\"}", liveLog.logbuffer]];
        self.log = dataStr;
    } else {
        [dataStr appendString:@"{\"frame\":["];
        for (int i = 0; i < RL_FRAME_NUMBER_FOR_MODEL; i++) {
            ReflectionLivenessImageData imageData = liveLog.frames[i];
            NSData *data = [FaceLiveUtils convertRawBufferToImage:imageData.image imageName:@"frame.jpg" cols:env.image_width rows:env.image_height saveImage:false];
            NSString *base64 = [data base64EncodedStringWithOptions:0];
            [dataStr appendString:[NSString stringWithFormat:@"\"%@\"", base64]];
            if (i < RL_FRAME_NUMBER_FOR_MODEL - 1) {
                [dataStr appendString:@","];
            }
        }
        //    NSString* logStr = [[NSString alloc] initWithCharacters:liveLog.logbuffer length:liveLog.bufferlen];
        [dataStr appendString:[NSString stringWithFormat:@"];\"log\":\"%s\"}", liveLog.logbuffer]];
        self.log = dataStr;
    }

    return 0;
}

- (void)setMaskRadiusRatio:(float)maskRadiusRatio offsetToCenterRatio:(float)offsetToCenterRatio {
    @synchronized(self) {
        ReflectionLiveness_SetParamF(_handle, REFLECTION_LIVENESS_MASK_RADIUS_RATIO, (void *)(&maskRadiusRatio));
        ReflectionLiveness_SetParamF(_handle, REFLECTION_LIVENESS_OFFSET_TO_CENTER_RATIO, (void *)(&offsetToCenterRatio));
    }
}

- (void)dealloc {
    NSLog(@"ReflectionLiveness dealloc.\n");
    if (!_is_released) {
        ReflectionLiveness_ReleaseHandle(_handle);
        _is_released = true;
    }
}

@end
