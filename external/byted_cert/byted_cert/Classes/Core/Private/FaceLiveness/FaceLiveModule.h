//
//  FaceLiveModule.h
//  FaceLiveModule
//
//  Created by LiuChundian on 2019/3/22.
//  Copyright © 2019年 Liuchundian. All rights reserved.

#import <CoreImage/CoreImage.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <smash/tt_common.h>

typedef struct FaceLiveInfo {
    int category;
    int time_remaind;
    int status;
    int state_machine_stage;
    //  int is_valided_face_catched;
    int detect_result_code;
    int action_number;
} FaceLiveInfo;

typedef struct FaceRiskLabel {
    int risk_multi;       // 0: 最多出现过几个人
    int risk_light;       // 0: 光线过暗 1：光线正常 2：光线过亮 3：过暗、过亮都出现过 过程中光线状况
    float risk_age_lower; // 过程中出现过的最小年龄
    float risk_age_upper; // 过程中出现过的最大年龄
    int risk_action;
} FaceRiskLabel;

typedef struct FaceQualityInfo {
    unsigned int face_quality;
    int prompt;
} FaceQualityInfo;


@interface FaceLiveModule : CIFilter

@property (nonatomic, strong) NSData *faceImageData;
@property (nonatomic, strong) NSData *faceWithEnvImageData;
@property (nonatomic, strong) NSData *eyeImageData;
@property (nonatomic, strong) NSData *mouthImageData;
@property (nonatomic, strong) NSData *nodImageData;
@property (nonatomic, strong) NSData *shakeImageData;

@property (nonatomic, strong) NSData *livenessImageData;
@property (nonatomic, strong) NSData *verifyImageData;
@property (nonatomic, strong) NSData *verifyOriImageData;
@property (nonatomic, strong) NSString *logBuffer;
@property (nonatomic, assign) BOOL maskFlag;
@property (nonatomic, assign) FaceRiskLabel riskLabel;

@property (nonatomic, assign) int algoErrorCode;

- (CGImageRef)doFaceLive:(CVPixelBufferRef)pixelBuffer
                  orient:(ScreenOrient)orient
                     ret:(FaceLiveInfo *)ret;

- (int)setParamsWithActions:(int *)actions
                 action_num:(int)action_num
                    timeout:(int)timeout;

- (int)setParamsGeneral:(int)type value:(float)value;

// 如果活动活体失败，重试的时候需要重置算法
- (int)reStart;

//- (void)saveBestImag;

- (int)setRandom:(int)action_num;

- (int)doFaceQuality:(CVPixelBufferRef)pixelBuffer
              orient:(ScreenOrient)orient
                 ret:(FaceQualityInfo *)ret;

- (void)setMaskRadiusRatio:(float)maskRadiusRatio offsetToCenterRatio:(float)offsetToCenterRatio;

- (void)saveErrorLog;

- (NSString *)hashSignForFramesHash:(NSArray *)framesHash;
- (NSString *)frameHash:(CVPixelBufferRef)pixels;

@end
