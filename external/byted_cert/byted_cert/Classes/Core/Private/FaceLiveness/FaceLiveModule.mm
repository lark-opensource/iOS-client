
#if defined(__ARM_NEON)

#import "ActionLiveness_API.h"
#import "ActionLiveness_Model.h"
#import "FaceLiveModule.h"
#import "FaceLiveUtils.h"
#import <stdlib.h>
#import <time.h>
#import <algorithm>
#import <string>
#import "BDCTLog.h"
#import <UIKit/UIKit.h>
#import "BDCTAdditions.h"
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <CommonCrypto/CommonDigest.h>

// 与 Native 层的交互

#define SETPARAM_CHECK(code)                     \
    if (!(code))                                 \
        ;                                        \
    else {                                       \
        self.algoErrorCode = code;               \
        NSLog(@"Set Param err, code: %d", code); \
        return nil;                              \
    };


@interface FaceLiveModule ()
{
    ActionLivenessHandle _handle;
    bool _is_released;
    bool _is_image_saved;
    FaceLiveInfo _info_ret;
}

- (uint)getActionCode:(int *)actionList num:(int)actionNum;

@end


@implementation FaceLiveModule

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    _is_released = false;
    _is_image_saved = false;
    int ret = ActionLiveness_CreateHandle(&_handle);
    if (ret != SMASH_OK) {
        NSLog(@"FaceLiveness Create error, code: %d", ret);
        return nil;
    }
    NSString *modelName = @"";
    ActionLivenessModelName modelInfo = {0};
    if (ActionLiveness_GetModelVersion(&modelInfo) == 0)
        modelName = [NSString stringWithUTF8String:modelInfo.namebuffer];

    NSString *res = [[NSBundle bdct_bundle] pathForResource:modelName ofType:nil];

    if (res == nil) {
        res = [FaceLiveUtils getResource:@"action_liveness.bundle" resName:modelName];
    }
    NSLog(@"FaceLiveness model: %@", res);
    if (res == nil) {
        return nil;
    }

    const char *model_path = [res UTF8String];
    SETPARAM_CHECK(ActionLiveness_LoadModel(_handle, kActionLivenessModel1, model_path));

    int use_random = 0;
    SETPARAM_CHECK(ActionLiveness_SetParamS(_handle, ACTION_LIVENESS_RANDOM_ORDER, (void *)(&use_random)));

    // TODO
    NSArray *actionArrays = @[ @(0), @(2), @(3) ];
    actionArrays = [FaceLiveUtils sortedRandomArrayByArray:actionArrays];
    int action_num = 1;
    int actions[action_num];
    actions[0] = [[actionArrays btd_objectAtIndex:0] intValue];
    int actions_list = [self getActionCode:actions num:action_num];
    SETPARAM_CHECK(ActionLiveness_SetParamS(_handle, ACTION_LIVENESS_ACTION_LIST, (void *)(&actions_list)));

    SETPARAM_CHECK(ActionLiveness_SetParamS(_handle, ACTION_LIVENESS_DETECT_ACTION_NUMBER, (void *)(&action_num)));

    return self;
}

- (int)setParamsWithActions:(int *)actions action_num:(int)action_num timeout:(int)timeout {
    @synchronized(self) {
        uint actions_list = [self getActionCode:actions num:action_num];
        int ret = ActionLiveness_SetParamS(_handle, ACTION_LIVENESS_ACTION_LIST, (void *)(&actions_list));
        if (ret != SMASH_OK) {
            self.algoErrorCode = ret;
            BDCTLogInfo(@"ret code: %d\n", ret);
            return -1;
        }
        if (action_num == 0) {
            action_num = 1;
        }
        ret = ActionLiveness_SetParamS(_handle, ACTION_LIVENESS_DETECT_ACTION_NUMBER, (void *)(&action_num));
        if (ret != SMASH_OK) {
            self.algoErrorCode = ret;
            BDCTLogInfo(@"ret code: %d\n", ret);
            return -1;
        }

        float time = timeout;
        // Set max timeout
        ret = ActionLiveness_SetParamS(_handle, ACTION_LIVENESS_TIME_PER_ACTION, (void *)(&time));
        if (ret != SMASH_OK) {
            self.algoErrorCode = ret;
            BDCTLogInfo(@"ret code: %d\n", ret);
            return -1;
        }

        return 0;
    }
}

- (int)setParamsGeneral:(int)type value:(float)value {
    @synchronized(self) {
        int ret = ActionLiveness_SetParamS(_handle, (ActionLivenessParamType)type, (void *)(&value));
        if (ret != SMASH_OK) {
            self.algoErrorCode = ret;
            BDCTLogInfo(@"ret code: %d\n", ret);
            return -1;
        }
        return 0;
    }
}

- (int)reStart {
    @synchronized(self) {
        int reset = 1;
        return ActionLiveness_SetParamS(_handle, ACTION_LIVENESS_RESET, (void *)(&reset));
    }
}

- (CGImageRef)doFaceLive:(CVPixelBufferRef)pixelBuffer
                  orient:(ScreenOrient)orient
                     ret:(FaceLiveInfo *)ret {
    @synchronized(self) {
        if (_is_released) {
            return nil;
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, 0);

        OSType format = CVPixelBufferGetPixelFormatType(pixelBuffer);
        unsigned char *baseAddress = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        unsigned long height = CVPixelBufferGetHeight(pixelBuffer);
        unsigned long stride = CVPixelBufferGetBytesPerRow(pixelBuffer);
        unsigned long width = CVPixelBufferGetWidth(pixelBuffer);

        if (format == kCVPixelFormatType_32BGRA) {
            ActionLivenessArgs arg;
            ActionLivenessRet output;

            arg.base.image = baseAddress;
            arg.base.image_height = (int)height;
            arg.base.image_width = (int)width;
            arg.base.image_stride = (int)stride;
            arg.base.pixel_fmt = kPixelFormat_BGRA8888;
            arg.base.orient = orient;

            int status = ActionLiveness_Predict(_handle, &arg, &output);
            if (status != SMASH_OK) {
                NSLog(@"LivenessPredict err, status: %d\n", status);
            }

            ret->category = output.category;
            ret->time_remaind = output.timeleft;
            ret->status = output.prompt_info - 101;
            ret->state_machine_stage = output.state_machine_stage; //todo
            ret->detect_result_code = output.detect_result_code;
            ret->action_number = output.action_number;
            if (output.detect_result_code == 1 && !_is_image_saved) {
                [self saveBestImag];
                _is_image_saved = true;
            }
        }

        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        return nil;
    }
}

- (int)doFaceQuality:(CVPixelBufferRef)pixelBuffer
              orient:(ScreenOrient)orient
                 ret:(FaceQualityInfo *)ret {
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);

    OSType format = CVPixelBufferGetPixelFormatType(pixelBuffer);
    unsigned char *baseAddress = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    unsigned long height = CVPixelBufferGetHeight(pixelBuffer);
    unsigned long stride = CVPixelBufferGetBytesPerRow(pixelBuffer);
    unsigned long width = CVPixelBufferGetWidth(pixelBuffer);

    if (format == kCVPixelFormatType_32BGRA) {
        ActionLivenessArgs arg;
        ActionLivenessFrameQuality output;

        arg.base.image = baseAddress;
        arg.base.image_height = (int)height;
        arg.base.image_width = (int)width;
        arg.base.image_stride = (int)stride;
        arg.base.pixel_fmt = kPixelFormat_BGRA8888;
        arg.base.orient = orient;

        int status = ActionLiveness_PredQuality(_handle, &arg, &output);
        if (status != SMASH_OK) {
            NSLog(@"LivenessPredict err, status: %d\n", status);
            return status;
        }

        ret->face_quality = output.face_quality;
        ret->prompt = output.recommend_prompt - 101;
    }

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    return SMASH_OK;
}

- (void)saveBestImag {
    ActionLivenessBestFrame env, face;
    // RGBA
    ActionLiveness_BestFrame(_handle, &env, &face);
    if (face.image != nullptr) {
        self.faceImageData = [FaceLiveUtils convertRawBufferToImage:face.image imageName:@"face.jpg" cols:face.image_width rows:face.image_height saveImage:false];
    }
    if (env.image != nullptr) {
        self.faceWithEnvImageData = [FaceLiveUtils convertRawBufferToImage:env.image imageName:@"env.jpg" cols:env.image_width rows:env.image_height saveImage:false];
    }
#if BD_CERT_ENABLE_MASK_LIVENESS
    if (env.mask_flag) {
        self.maskFlag = YES;
    }
    ActionLivenessBestFrame eye, mouth, nod, shake;
    ActionLivenessActFrame actFrames;
    ActionLiveness_GetExtremFrame(_handle, &actFrames);
    eye = actFrames.e_eye_image;
    mouth = actFrames.e_mouth_image;
    nod = actFrames.e_nod_image;
    shake = actFrames.e_shake_image;
    if (eye.image != nullptr) {
        self.eyeImageData = [FaceLiveUtils convertRawBufferToImage:eye.image imageName:@"eye.jpg" cols:eye.image_width rows:eye.image_height saveImage:false];
    }

    if (mouth.image != nullptr) {
        self.mouthImageData = [FaceLiveUtils convertRawBufferToImage:mouth.image imageName:@"mouth.jpg" cols:mouth.image_width rows:mouth.image_height saveImage:false];
    }

    if (nod.image != nullptr) {
        self.nodImageData = [FaceLiveUtils convertRawBufferToImage:nod.image imageName:@"nod.jpg" cols:nod.image_width rows:nod.image_height saveImage:false];
    }

    if (shake.image != nullptr) {
        self.shakeImageData = [FaceLiveUtils convertRawBufferToImage:shake.image imageName:@"shake.jpg" cols:shake.image_width rows:shake.image_height saveImage:false];
    }
#endif

#if BD_CERT_ENABLE_RISK_LABEL_LIVENESS
    ActionLivenessRiskLabel actionRiskLabel;
    ActionLiveness_GetRiskLabel(_handle, &actionRiskLabel);
    FaceRiskLabel faceRiskLabel;
    faceRiskLabel.risk_multi = actionRiskLabel.risk_multi;
    faceRiskLabel.risk_light = actionRiskLabel.risk_light;
    faceRiskLabel.risk_age_lower = actionRiskLabel.risk_age_lower;
    faceRiskLabel.risk_age_upper = actionRiskLabel.risk_age_upper;
    faceRiskLabel.risk_action = actionRiskLabel.risk_action;
    self.riskLabel = faceRiskLabel;
#endif
}

- (void)saveErrorLog {
    ActionLivenessResultLog log;

    ActionLiveness_GetFramesLog(_handle, &log);

    self.logBuffer = [NSString stringWithFormat:@"%s", log.logbuffer];

    if (log.liveness_image.image != nullptr)
        self.livenessImageData = [FaceLiveUtils convertRawBufferToImage:log.liveness_image.image imageName:@"liveness.jpg" cols:log.liveness_image.image_width rows:log.liveness_image.image_height saveImage:false];
    if (log.face_verify_image[0].image != nullptr) {
        self.verifyOriImageData = [FaceLiveUtils convertRawBufferToImage:log.face_verify_image[0].image imageName:@"verify_ori.jpg" cols:log.face_verify_image[0].image_width rows:log.face_verify_image[0].image_height saveImage:false];
    }
    if (log.face_verify_image[1].image != nullptr) {
        self.verifyImageData = [FaceLiveUtils convertRawBufferToImage:log.face_verify_image[1].image imageName:@"verify.jpg" cols:log.face_verify_image[1].image_width rows:log.face_verify_image[1].image_height saveImage:false];
    }
}

- (void)dealloc {
    NSLog(@"FaceLiveModule dealloc.\n");
    @synchronized(self) {
        if (!_is_released) {
            _is_released = true;
            ActionLiveness_Release(_handle);
        }
    }
}

- (uint)getActionCode:(int *)actionList num:(int)actionNum {
    if (actionList == nil || actionNum < 1) {
        return 0;
    }
    uint act = 0xffffff00;
    for (int i = 0; i < actionNum; i++) {
        int action = actionList[i];
        int pos = 8 + action * 3;
        uint mask = ~(0x07 << pos);
        uint v = ((i + 1) << pos) | mask;
        act &= v;
    }
    act &= 0x03ffffff;
    return act;
}

- (int)setRandom:(int)action_num {
    @synchronized(self) {
        NSArray *actionArrays = @[ @(0), @(2), @(3) ];
        actionArrays = [FaceLiveUtils sortedRandomArrayByArray:actionArrays];
        int actions[action_num];
        for (int i = 0; i < action_num; i++) {
            actions[i] = [[actionArrays objectAtIndex:i] intValue];
        }
        int actions_list = [self getActionCode:actions num:action_num];
        int ret = ActionLiveness_SetParamS(_handle, ACTION_LIVENESS_ACTION_LIST, (void *)(&actions_list));
        if (ret != 0) {
            return ret;
        }
        ret = ActionLiveness_SetParamS(_handle, ACTION_LIVENESS_DETECT_ACTION_NUMBER, (void *)(&action_num));

        return ret;
    }
}

- (void)setMaskRadiusRatio:(float)maskRadiusRatio offsetToCenterRatio:(float)offsetToCenterRatio {
    @synchronized(self) {
        ActionLiveness_SetParamS(_handle, ACTION_LIVENESS_MASK_RADIUS_RATIO, (void *)(&maskRadiusRatio));
        ActionLiveness_SetParamS(_handle, ACTION_LIVENESS_OFFSET_TO_CENTER_RATIO, (void *)(&offsetToCenterRatio));
    }
}

- (NSString *)hashSignForFramesHash:(NSArray *)framesHash {
    NSString *hashStr = [framesHash componentsJoinedByString:@";"];
    NSData *data = [hashStr dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, digest);
    NSMutableString *hashSign = [NSMutableString string];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [hashSign appendFormat:@"%02x", digest[i]];
    }
    return hashSign.copy;
}

- (NSString *)frameHash:(CVPixelBufferRef)pixels {
    CVPixelBufferLockBaseAddress(pixels, 0);

    size_t length = CVPixelBufferGetDataSize(pixels);
    unsigned char *imageData = (unsigned char *)CVPixelBufferGetBaseAddress(pixels);
    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(imageData, (CC_LONG)length, digest);
    CVPixelBufferUnlockBaseAddress(pixels, 0);
    NSMutableString *hashStr = [NSMutableString string];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [hashStr appendFormat:@"%02x", digest[i]];
    }
    return hashStr.copy;
}

@end

#else

#import "ActionLiveness_API.h"

#import "FaceLiveModule.h"
#import "FaceLiveUtils.h"
#import <stdlib.h>
#import <time.h>
#import <algorithm>
#import <string>
#import <UIKit/UIKit.h>


@interface FaceLiveModule ()

@end


@implementation FaceLiveModule

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    return nil;
}

- (int)setParamsWithActions:(int *)actions action_num:(int)action_num timeout:(int)timeout {
    return SMASH_E_NOT_IMPL;
}

- (int)reStart {
    return SMASH_E_NOT_IMPL;
}

- (CGImageRef)doFaceLive:(CVPixelBufferRef)pixelBuffer
                  orient:(ScreenOrient)orient
                     ret:(FaceLiveInfo *)ret {
    return nil;
}

- (int)doFaceQuality:(CVPixelBufferRef)pixelBuffer orient:(ScreenOrient)orient ret:(FaceQualityInfo *)ret {
    return -1;
}

- (void)saveBestImag {
}

- (int)setRandom:(int)action_num {
    return SMASH_E_NOT_IMPL;
}

- (void)setMaskRadiusRatio:(float)maskRadiusRatio offsetToCenterRatio:(float)offsetToCenterRatio {
    SMASH_E_NOT_IMPL;
}

@end

#endif
