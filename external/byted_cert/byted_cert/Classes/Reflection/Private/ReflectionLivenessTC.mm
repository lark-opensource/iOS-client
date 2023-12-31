//
//  ReflectionLivenessVC.h
//  Pods
//
//  Created by zhengyanxin on 2020/12/20.
//
#import "ReflectionLivenessTC.h"
#import "FaceLiveViewController+Layout.h"
#import "BDCTLocalization.h"
#import "BDCTEventTracker+ReflectionLiveness.h"
#import "ReflectionLivenessModule.h"
#import "FaceLiveUtils.h"
#import "BDCTStringConst.h"
#import "BDCTFlow.h"

#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/UIColor+BTDAdditions.h>


@interface ReflectionLivenessTC ()

@property (nonatomic, strong) ReflectionLiveness *faceliveInstance;

//log track
@property (nonatomic, assign) int prevMotion;
@property (nonatomic, assign) int frameCount;
@property (nonatomic, strong) NSMutableArray *promptInfoArray;
@property (nonatomic, strong) NSMutableArray *colorArray;
@property (nonatomic, assign) NSUInteger lastPromptInfoArrayCount;

/// 中断次数
@property (nonatomic, assign) NSInteger interruptTimes;

//@property (nonatomic, assign) FaceLiveInfo mLastInfo;

@property (nonatomic, assign) CGFloat prevPro;
@property (atomic, assign) BOOL isDetecting;

@property (nonatomic, weak) FaceLiveViewController *faceVC;

@property (nonatomic, assign) ReflectionLiveInfo lastInfo;

@property (nonatomic, assign) NSInteger lastTipsTime;

@end


@implementation ReflectionLivenessTC

- (instancetype)initWithVC:(FaceLiveViewController *)vc {
    self = [super init];
    if (!self) {
        return nil;
    }

    _faceVC = vc;
    _faceliveInstance = [[ReflectionLiveness alloc] init];
    _prevPro = 0.0f;
    _promptInfoArray = [NSMutableArray array];
    _colorArray = [NSMutableArray array];
    _lastTipsTime = 0;
    self.isDetecting = YES;
    return self;
}

- (int)setInitParams:(NSDictionary *)params {
    return 0;
}

- (int)setParamsGeneral:(int)type value:(float)value {
    return [_faceliveInstance setParamsGeneral:type value:value];
}

- (void)reStart:(int)type {
    _prevPro = -1.0f;
    _lastTipsTime = 0;
    self.isDetecting = YES;
    [self.faceliveInstance reStart:type];
}

- (CGImageRef)doFaceLive:(CVPixelBufferRef)pixels
                  orient:(ScreenOrient)orient {
    if (!self.isDetecting)
        return nil;
    ReflectionLiveInfo info;
    [_faceliveInstance doFaceLive:pixels orient:orient ret:&info];

    NSString *boardStr;
    UIColor *color = BytedCertUIConfig.sharedInstance.backgroundColor;
    BOOL showRet = YES;
    CGFloat progress = 0.0f;

    boardStr = [bdct_reflection_status_strs() btd_objectAtIndex:info.status];

    if (info.state_machine_stage == RL_WARMUP_STAGE) {
    } else if (info.state_machine_stage == RL_WAITFACE_STAGE) {
    } else if (info.state_machine_stage == RL_REFLECTION_STAGE) {
        if (_lastInfo.state_machine_stage != RL_REFLECTION_STAGE) {
            [_colorArray removeAllObjects];
        }
        if (info.light != -1) {
            color = [UIColor btd_colorWithRGB:info.light];
            if (!_colorArray.count || [_colorArray.lastObject intValue] != info.light) {
                [_colorArray addObject:@(info.light)];
            }
        }
        if (boardStr == nil || [boardStr isEqualToString:@""]) {
            if (info.light != -1) {
                boardStr = BytedCertLocalizedString(@"请保持姿势不变");
            } else {
                boardStr = BytedCertLocalizedString(@"屏幕即将闪烁，请保持姿势不变");
            }
        }
        progress = info.process;
        showRet = NO;
    } else if (info.state_machine_stage == RL_FINISH_STAGE) {
        if (info.detect_result_code == RL_RESULT_INVALID) {
            [self reStart:1];
        } else {
            self.isDetecting = NO;
            NSDictionary *dict = [self packSDKData:info.detect_result_code == RL_RESULT_REAL];
            [self.faceVC liveDetectSuccessWithPackedParams:dict
                                                  faceData:self.faceliveInstance.faceWithEnvImageData
                                                resultCode:info.detect_result_code - 200];
        }
    }

    if (_lastInfo.status > 0 && (!_promptInfoArray.count || _lastInfo.status != [_promptInfoArray.lastObject intValue])) {
        [_promptInfoArray addObject:@(_lastInfo.status)];
    }
    // 炫彩状态切换 埋点
    if (_lastInfo.state_machine_stage != info.state_machine_stage) {
        if (_lastInfo.state_machine_stage == RL_WAITFACE_STAGE) {
            if (info.state_machine_stage == RL_REFLECTION_STAGE) {
                // 质量检测成功
                [self.faceVC.bdct_flow.eventTracker trackReflectionLivenessDetectionColorQualityResult:YES promptInfo:_promptInfoArray];
            } else if (info.state_machine_stage == RL_FINISH_STAGE) {
                // 质量检测失败
                [self.faceVC.bdct_flow.eventTracker trackReflectionLivenessDetectionColorQualityResult:NO promptInfo:_promptInfoArray];
            }
            [_promptInfoArray removeAllObjects];
        } else if (info.state_machine_stage == RL_FINISH_STAGE) {
            if (info.detect_result_code == RL_RESULT_INVALID) {
                // 炫彩中断
                _interruptTimes++;
            } else {
                // 炫彩结束
                [self.faceVC.bdct_flow.eventTracker trackReflectionLivenessDetectionResult:(info.detect_result_code == RL_RESULT_REAL) colorPromptInfo:_promptInfoArray colorList:_colorArray interruptTimes:(int)_interruptTimes errorCode:info.detect_result_code];
            }
            [_promptInfoArray removeAllObjects];
        }
    }
    self.lastInfo = info;

    dispatch_sync(dispatch_get_main_queue(), ^{
        NSInteger curTime = NSDate.date.timeIntervalSince1970 * 1000;
        if (curTime - _lastTipsTime > 500) {
            self.faceVC.actionTipLabel.text = boardStr;
            self.lastTipsTime = curTime;
        }
        self.faceVC.mainWrapperView.backgroundColor = color;
        if (progress - _prevPro > 0.02) {
            self.faceVC.circleProgressTrackLayer.strokeEnd = progress;
            _prevPro = progress;
        }
        [self.faceVC.backButton setHidden:!showRet];
    });
    return nil;
}

- (void)viewDismiss {
}

- (NSDictionary *)packSDKData:(BOOL)isSuccess {
    [self.faceliveInstance saveInfo];
    NSString *log = self.faceliveInstance.log;
    NSString *b64Face = @"";
    NSString *b64FaceWithEnv = @"";
    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                                                 //                                 self.params[@"liveness_timeout"], @"liveness_timeout",
                                                                 //                                 self.params[@"motion_types"], @"motion_types",
                                                                 isSuccess ? @"1" : @"0", @"faceliveness_result",
                                                                 log, @"log",
                                                                 nil];
    if (self.faceliveInstance.faceImageData != nil) {
        b64Face = [self.faceliveInstance.faceImageData base64EncodedStringWithOptions:0];
        b64FaceWithEnv = [self.faceliveInstance.faceWithEnvImageData base64EncodedStringWithOptions:0];
        data[@"image_env"] = b64FaceWithEnv;
        data[@"image_face"] = b64Face;
    }

    NSMutableString *dataStr = [[NSMutableString alloc] init];
    NSUInteger size = [data count];
    NSUInteger i = 0;
    for (NSString *key in data.allKeys) {
        [dataStr appendString:[NSString stringWithFormat:@"%@=%@", key, data[key]]];
        if (i < size - 1) {
            [dataStr appendString:@"&"];
        }
        i += 1;
    }

    BOOL newCryptType = NO;
    NSString *cryptStr = [FaceLiveUtils packData:dataStr.copy newCryptType:&newCryptType] ?: @"";
    NSString *sdkDataVersion = newCryptType ? @"2.0" : @"3.0"; // 旧版加密用3.0，新版2.0

    NSMutableString *sdkStr = [[NSMutableString alloc] init];
    if (cryptStr.length) {
        int verStrLen = (int)[sdkDataVersion length];
        [sdkStr appendString:[NSString stringWithFormat:@"%c", verStrLen]];
        [sdkStr appendString:sdkDataVersion];
        [sdkStr appendString:cryptStr];
    }
    NSDictionary *dict = @{
        @"sdk_data" : [sdkStr dataUsingEncoding:NSUTF8StringEncoding],
        @"image_env" : b64FaceWithEnv,
        @"image_face" : b64Face
    };
    return dict;
}

- (void)trackCancel {
    if (_lastInfo.state_machine_stage == RL_REFLECTION_STAGE) {
        [self.faceVC.bdct_flow.eventTracker trackReturnPreviousPageFromPosition:@"face_detection_color"];
    } else {
        [self.faceVC.bdct_flow.eventTracker trackReturnPreviousPageFromPosition:@"face_detection_color_quality"];
    }
}

- (int)getAlgoErrorCode {
    return _faceliveInstance.algoErrorCode;
}

- (NSString *)getLivenessErrorTitle:(int)code {
    int realCode = code + 200;
    if (realCode == RL_RESULT_TIMEOUT || realCode == RL_RESULT_OVER_MAXRETRY_TIMES) { // 3: 单个动作超时
        return BytedCertLocalizedString(@"炫彩超时");
    }
    return BytedCertLocalizedString(@"检测失败");
}

- (void)setMaskRadiusRatio:(float)maskRadiusRadio offsetToCenterRatio:(float)offsetToCenterRatio {
    [_faceliveInstance setMaskRadiusRatio:maskRadiusRadio offsetToCenterRatio:offsetToCenterRatio];
}

@end
