//
//  ReflectionLiveness.m
//  Pods
//
//  Created by zhengyanxin on 2020/12/18.
//

#import <Foundation/Foundation.h>


#import <CoreImage/CoreImage.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <smash/tt_common.h>

typedef struct ReflectionLiveInfo {
    int category;
    int time_remaind;
    int status;
    int state_machine_stage;
    //  int is_valided_face_catched;
    int detect_result_code;

    int light;
    float process;
} ReflectionLiveInfo;


@interface ReflectionLiveness : CIFilter

@property (nonatomic, strong) NSData *faceImageData;
@property (nonatomic, strong) NSData *faceWithEnvImageData;
@property (nonatomic, strong) NSString *log;

@property (nonatomic, assign) int algoErrorCode;

- (int)setParamsGeneral:(int)type value:(float)value;

- (CGImageRef)doFaceLive:(CVPixelBufferRef)pixelBuffer
                  orient:(ScreenOrient)orient
                     ret:(ReflectionLiveInfo *)ret;

// 如果活动活体失败，重试的时候需要重置算法
- (int)reStart:(int)type;

- (void)setMaskRadiusRatio:(float)maskRadiusRatio offsetToCenterRatio:(float)offsetToCenterRatio;

- (int)saveInfo;


@end
