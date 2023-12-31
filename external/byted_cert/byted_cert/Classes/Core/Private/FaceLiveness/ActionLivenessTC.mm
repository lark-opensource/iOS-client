//
//  ActionLivenessVC.h
//  Pods
//
//  Created by zhengyanxin on 2020/12/20.
//
#import "ActionLivenessTC.h"
#import "FaceLiveModule.h"
#import "BDCTLocalization.h"
#import "BDCTEventTracker.h"
#import "FaceLiveUtils.h"
#import "BDCTStringConst.h"
#import "BDCTLog.h"
#import "BDCTFlow.h"
#import "BDCTEventTracker+ActionLiveness.h"
#import "BDCTAPIService.h"
#import "FaceLiveViewController+Layout.h"
#import "FaceLiveViewController+Audio.h"

#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

#define UI_INTERVAL 0.01 // second

typedef NS_ENUM(NSUInteger, BytedCertFaceDetectResult) {
    BytedCertFaceDetectResultUnFinish = 0,                 // 检测尚未完成
    BytedCertFaceDetectResultSuccess = 1,                  // 检测成功
    BytedCertFaceDetectResultTimeOut = 2,                  // 超时未检测到第一张有效人脸
    BytedCertFaceDetectResultOneActionTimeOut = 3,         // 单个动作超时
    BytedCertFaceDetectResultLoseReachMax = 4,             // 人脸丢失超过最大允许次数
    BytedCertFaceDetectResultREIDTimeOut = 5,              // 人脸REID超时
    BytedCertFaceDetectResultActionMistake = 6,            // 做错动作，可能是视频攻击
    BytedCertFaceDetectResultSilenceDetectFailure = 7,     // 静默活体检测失败
    BytedCertFaceDetectResultFaceNotMatch = 8,             // 过程中人脸不一致
    BytedCertFaceDetectResultSilenceDetectNetFailure = 99, // 服务端静默活体失败
};


@interface ActionLivenessTC ()
@property (nonatomic, strong) FaceLiveModule *faceliveInstance;
@property (nonatomic, assign) NSInteger livenessTimeout;
@property (nonatomic, strong) NSDictionary *params;
@property (nonatomic, copy) NSString *motionsString;

//logic control
@property (atomic, assign) BOOL isDetecting;
@property (nonatomic, assign) int lessDiffFaceTime;
@property (nonatomic, assign) NSInteger maxTimeout; // TODO

//ui control
@property (nonatomic, strong) NSTimer *ui_timer;
@property (nonatomic, assign) int lastTimeRemaind;
@property (nonatomic, assign) float countDownTimeRemaind;
@property (nonatomic, assign) BOOL countDownStart;

@property (atomic, assign) BOOL turnLight;
@property (atomic, assign) BOOL isFinish;
@property (nonatomic, assign) float brightess;

//log track
@property (nonatomic, assign) int prevMotion;
@property (nonatomic, assign) int frameCount;
@property (nonatomic, strong) NSMutableArray *promptInfoArray;
@property (nonatomic, assign) NSUInteger lastPromptInfoArrayCount;
@property (nonatomic, assign) FaceLiveInfo lastInfo;
@property (nonatomic, assign) int lastMachineStage;

@property (nonatomic, assign, readonly) BOOL logMode;
@property (nonatomic, assign, readonly) BOOL securityMode;
@property (nonatomic, strong) NSMutableArray *frameHashes;
@property (nonatomic, assign) NSUInteger hashDuration;

@property (nonatomic, weak) FaceLiveViewController *faceVC;

@end


@implementation ActionLivenessTC

- (instancetype)initWithVC:(FaceLiveViewController *)vc {
    self = [super init];
    if (!self) {
        return nil;
    }

    _faceVC = vc;
    _faceliveInstance = [[FaceLiveModule alloc] init];
    _promptInfoArray = [[NSMutableArray alloc] init];

    [self clearTimer];

    self.maxTimeout = 9;
    self.countDownStart = NO;
    self.isDetecting = YES;
    self.frameCount = 0;
    self.turnLight = NO;
    self.isFinish = NO;
    self.lessDiffFaceTime = 2;
    self.livenessTimeout = 10;
    [_faceliveInstance setParamsGeneral:1 value:(float)self.livenessTimeout];
    return self;
}

- (BOOL)logMode {
    if (self.faceVC.bdct_flow.context.parameter.useSystemV2) {
        return [self.params btd_boolValueForKey:@"log_mode_v3"];
    }
    return [self.params btd_boolValueForKey:@"log_mode"];
}

- (BOOL)securityMode {
    return [self.params btd_boolValueForKey:@"security_mode"];
}

- (NSMutableArray *)frameHashes {
    if (!_frameHashes) {
        _frameHashes = [NSMutableArray array];
    }
    return _frameHashes;
}

- (int)setInitParams:(NSDictionary *)params {
    self.params = params;
    //解析params设置参数
    if (params[@"liveness_timeout"]) {
        self.livenessTimeout = [params[@"liveness_timeout"] integerValue];
    }
    NSString *motionTypes = [params btd_stringValueForKey:@"motion_types"];
    self.motionsString = motionTypes;
    if (!motionTypes.length) {
        motionTypes = nil;
    }
    NSArray *motionStrTypes = [motionTypes componentsSeparatedByString:@","];
    int size = (int)[motionStrTypes count];
    int *motion_types = (int *)malloc(sizeof(int) * size);
    for (int i = 0; i < size; ++i) {
        motion_types[i] = (int)[motionStrTypes[i] integerValue];
        if (motion_types[i] == 2) {
            motion_types[i] = 4;
        } else if (motion_types[i] == 3) {
            motion_types[i] = 5;
        }
    }

    BDCTLogInfo(@" timeout = %d, motion types = %@\n", (int)self.livenessTimeout, motionTypes);
    self.prevMotion = motion_types[0];
    self.frameCount = 0;
    int ret = [_faceliveInstance setParamsWithActions:motion_types action_num:size timeout:(int)self.livenessTimeout];
    if (motion_types) {
        free(motion_types);
    }
    return ret;
}

- (int)setParamsGeneral:(int)type value:(float)value {
    return [_faceliveInstance setParamsGeneral:type value:value];
}

- (void)reStart:(int)type {
    _countDownStart = NO;
    self.lessDiffFaceTime = 2;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.isDetecting = YES;
    });
    [self.faceliveInstance reStart];
}

- (CGImageRef)doFaceLive:(CVPixelBufferRef)pixels
                  orient:(ScreenOrient)orient {
    FaceLiveInfo info;
    [_faceliveInstance doFaceLive:pixels orient:orient ret:&info];

    self.frameCount += 1;

    if (info.status == 6 && info.time_remaind > 0 && info.category != -1 && info.state_machine_stage == 0) {
        [self.faceVC.bdct_flow.eventTracker trackActionFaceDetectionLiveResult:nil motionList:self.motionsString promptInfos:self.promptInfoArray];
    }

    if (self.isDetecting) {
        if (info.status == 0 && info.time_remaind == 0 && info.state_machine_stage == 0) {
            if (self.prevMotion >= 0 && self.prevMotion <= 3) {
                [self.faceVC.bdct_flow.eventTracker trackActionFaceDetectionLiveResult:@(info.detect_result_code) motionList:self.motionsString promptInfos:self.promptInfoArray];
            }
        }
    }

    NSString *boardStr;
    NSString *cicleStr;
    if (info.state_machine_stage == 2) { // 如果检测一个人脸，并且还没未完成检测
        boardStr = [bdct_action_strs() btd_objectAtIndex:info.category];
        cicleStr = [bdct_circle_strs() btd_objectAtIndex:info.status];
        if (boardStr.length && self.promptInfoArray.count && self.promptInfoArray.count != self.lastPromptInfoArrayCount) {
            [self.faceVC.bdct_flow.eventTracker trackFaceDetectionPromptWithPromptInfo:[self.promptInfoArray copy] result:BytedCertTrackerPromptInfoTypeSuccess];
            self.lastPromptInfoArrayCount = self.promptInfoArray.count;
        }
        if (self.securityMode) {
            CFTimeInterval startTime = CACurrentMediaTime() * 1000;
            [self.frameHashes addObject:[self.faceliveInstance frameHash:pixels]];
            NSUInteger duration = CACurrentMediaTime() * 1000 - startTime;
            _hashDuration += duration;
        }
    } else { // 未检测到人脸或者已经检测完成
        boardStr = [bdct_status_strs() btd_objectAtIndex:info.status];

        if (self.promptInfoArray.count > 0) {
            NSNumber *lastStaus = [self.promptInfoArray lastObject];
            if ([lastStaus intValue] != info.status + 101) {
                [self.promptInfoArray addObject:@(info.status + 101)];
            }
        } else {
            [self.promptInfoArray addObject:@(info.status + 101)];
        }

        if (self.isDetecting) {
            if (info.detect_result_code == 0) { // 检测尚未完成
                // Do nothing
            } else if (info.detect_result_code == 1) { // 成功完成动作活体
                self.isDetecting = NO;
                // 埋点 =================================================================
                [self.faceVC.bdct_flow.eventTracker trackActionFaceDetectionLiveResult:nil motionList:self.motionsString promptInfos:self.promptInfoArray];
                // =====================================================================

                if (self.securityMode) { //上传图像hash
                    CFTimeInterval startTime = CACurrentMediaTime() * 1000;
                    [self.frameHashes addObject:[self.faceliveInstance frameHash:pixels]];
                    NSUInteger duration = CACurrentMediaTime() * 1000 - startTime;
                    _hashDuration += duration;
                    NSString *hashSign = [self.faceliveInstance hashSignForFramesHash:self.frameHashes];
                    [self.faceVC.bdct_flow.apiService bytedfaceHashUpload:nil faceImageHashes:self.frameHashes.copy hashDuration:_hashDuration hashSign:hashSign completion:nil];
                    [self.frameHashes removeAllObjects];
                    _hashDuration = 0;
                }
                // 成功 调用 compare 接口
                NSDictionary *dict = [self packSDKData];
                [self.faceVC liveDetectSuccessWithPackedParams:dict faceData:self.faceliveInstance.faceWithEnvImageData resultCode:0];
            } else { // 活体检测过程中出现失败
                self.isDetecting = NO;
                NSString *title = [self getLivenessErrorTitle:info.detect_result_code];
                int errorCode = info.detect_result_code;
                // 停止倒计时更新
                [self clearTimer];
                if (self.securityMode) {
                    [self.frameHashes removeAllObjects];
                    _hashDuration = 0;
                }
                //失败活体数据上传
                if ((self.logMode || self.faceVC.bdct_flow.context.parameter.logMode) && [@[ @(2), @(3), @(9) ] containsObject:@(info.detect_result_code)]) {
                    NSData *sdkData = [[self packLogData] dataUsingEncoding:NSUTF8StringEncoding];
                    [self.faceVC.bdct_flow.apiService bytedfaceFailUpload:nil sdkData:sdkData completion:nil];
                }
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    self.faceVC.circleProgressTrackLayer.strokeEnd = 0.0;

                    // 弹框提示重试
                    // 埋点 ===============================================================
                    if (errorCode == BytedCertFaceDetectResultOneActionTimeOut) {
                        [self.faceVC.bdct_flow.eventTracker trackFaceDetectionFailPopupWithActionType:@"alert_show" failReason:[bdct_log_event_action_liveness_fail_reasons() btd_objectAtIndex:errorCode] errorCode:errorCode];
                    } else if (errorCode == BytedCertFaceDetectResultTimeOut) {
                        [self.faceVC.bdct_flow.eventTracker trackFaceDetectionPromptWithPromptInfo:[self.promptInfoArray copy] result:BytedCertTrackerPromptInfoTypeFail];
                    }

                    // ===================================================================
                    [self.faceVC.bdct_flow.eventTracker trackActionFaceDetectionLiveResult:@(errorCode) motionList:self.motionsString promptInfos:self.promptInfoArray];

                    [self.faceVC liveDetectFailWithErrorTitle:title message:nil actionCompletion:^(NSString *_Nonnull action) {
                        [self.faceVC.bdct_flow.eventTracker trackFaceDetectionFailPopupWithActionType:action failReason:[bdct_log_event_action_liveness_fail_reasons() btd_objectAtIndex:errorCode] errorCode:errorCode];
                    }];
                });
            }
        }
    }
    self.prevMotion = info.category;

    // 必须在已经识别人脸活体检测过程中
    if (info.state_machine_stage == 2 || info.state_machine_stage == 0) {
        // 如果还没开始计时则开启倒计时
        if (_countDownStart == NO) {
            _lastTimeRemaind = info.time_remaind;
            _countDownTimeRemaind = info.time_remaind;
            _countDownStart = YES;

            dispatch_async(dispatch_get_main_queue(), ^{
                [self clearTimer];
                self->_ui_timer = [NSTimer scheduledTimerWithTimeInterval:UI_INTERVAL target:self selector:@selector(uiUpdate:) userInfo:nil repeats:YES];
            });
        }
        // 如果已经开启倒计时，则需要判断倒计时是否被刷新
        else {
            //通过上次剩余时间和当前剩余时间关系判断是否一个动作完成被刷新
            if (info.time_remaind > self.lastTimeRemaind || info.state_machine_stage != self.lastMachineStage) {
                self.lastMachineStage = info.state_machine_stage;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self clearTimer];
                    // 重新把倒计时圆环打满
                    self.faceVC.circleProgressTrackLayer.strokeEnd = 1.0;
                    self.lastTimeRemaind = info.time_remaind;
                    self.countDownTimeRemaind = info.time_remaind;
                    self->_ui_timer = [NSTimer scheduledTimerWithTimeInterval:UI_INTERVAL target:self selector:@selector(uiUpdate:) userInfo:nil repeats:YES];
                });
            } else {
                self.lastTimeRemaind = info.time_remaind;
            }
        }
    }

    dispatch_sync(dispatch_get_main_queue(), ^{
        //todo 可能和外部不同步
        self.faceVC.actionTipLabel.font = BytedCertUIConfig.sharedInstance.actionLabelFont ?: [UIFont systemFontOfSize:28];
        self.faceVC.actionTipLabel.text = boardStr;
        if (self.faceVC.bdct_flow.context.liveDetectionOpt) {
            if (boardStr.length) {
                self.faceVC.actionTipLabel.text = [NSString stringWithFormat:@"%@ (%d)", boardStr, info.time_remaind];
            }
            if (info.state_machine_stage == 2) {
                NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"还需完成%d个动作", info.action_number]];
                [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:254 / 255.0 green:44 / 2550 blue:85 / 255.0 alpha:0.5] range:NSMakeRange(4, 1)];
                if (info.action_number == 0 || info.action_number > 4) {
                    self.faceVC.actionCountTipLabel.text = @"";
                } else {
                    self.faceVC.actionCountTipLabel.attributedText = attributedString;
                }
            } else if (info.detect_result_code == 1) {
                self.faceVC.actionCountTipLabel.text = [NSString stringWithFormat:@"已完成全部动作，请勿退出"];
            }
        }

        if (cicleStr != nil && ![cicleStr isEqualToString:@""]) {
            [self.faceVC.smallActionTipLabel setHidden:NO];
            self.faceVC.smallActionTipLabel.text = cicleStr;
        } else {
            [self.faceVC.smallActionTipLabel setHidden:YES];
        }

        [self.faceVC playAudioWithActionTip:boardStr smallActionTip:cicleStr];

        if (info.status == 11 && !self.isFinish && !self.turnLight) {
            self.brightess = (float)[UIScreen mainScreen].brightness;
            [[UIScreen mainScreen] setBrightness:0.9];
            BDCTLogInfo(@"setBrightness:0.9");
            [UIApplication sharedApplication].idleTimerDisabled = YES;
            self.turnLight = YES;
        }
    });
    return nil;
}

- (void)viewDismiss {
    self.isFinish = YES;
    [self clearTimer];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.brightess > 0) {
            [[UIScreen mainScreen] setBrightness:CGFloat(self.brightess)];
        }
        BDCTLogInfo(@"setBrightness:%f", CGFloat(self.brightess));
    });
}

- (NSString *)getLivenessErrorTitle:(int)code {
    if (code == 3) { // 3: 单个动作超时
        return [NSString stringWithFormat:BytedCertLocalizedString(@"每个动作请在%lu秒内完成"), self.livenessTimeout];
    } else if (code == 2) {
        return BytedCertLocalizedString(@"未能检测到人脸");
    } else if (code == 9) {
        return BytedCertLocalizedString(@"请正对手机后再次认证");
    }
    return BytedCertLocalizedString(@"请按照提示做对应的动作");
}

- (NSDictionary *)packSDKData {
    NSString *b64Face = [self.faceliveInstance.faceImageData base64EncodedStringWithOptions:0];
    NSString *b64FaceWithEnv = [self.faceliveInstance.faceWithEnvImageData base64EncodedStringWithOptions:0];
    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                                                 b64FaceWithEnv, @"image_env",
                                                                 b64Face, @"image_face",
                                                                 @"1", @"faceliveness_result",
                                                                 @(self.faceliveInstance.maskFlag), @"mask_flag",
                                                                 nil];
#if BD_CERT_ENABLE_MASK_LIVENESS
    if (self.faceVC.bdct_flow.context.enableExtremeImg) {
        NSString *b64Eye = [self.faceliveInstance.eyeImageData base64EncodedStringWithOptions:0];
        NSString *b64Mouth = [self.faceliveInstance.mouthImageData base64EncodedStringWithOptions:0];
        NSString *b64Nod = [self.faceliveInstance.nodImageData base64EncodedStringWithOptions:0];
        NSString *b64Shake = [self.faceliveInstance.shakeImageData base64EncodedStringWithOptions:0];

        data[@"image_eye"] = b64Eye;
        data[@"image_mouth"] = b64Mouth;
        data[@"image_nod"] = b64Nod;
        data[@"image_shake"] = b64Shake;
    }
#endif

#if BD_CERT_ENABLE_RISK_LABEL_LIVENESS
    data[@"risk_multi"] = @(self.faceliveInstance.riskLabel.risk_multi);
    data[@"risk_light"] = @(self.faceliveInstance.riskLabel.risk_light);
    data[@"risk_age_lower"] = @(self.faceliveInstance.riskLabel.risk_age_lower);
    data[@"risk_age_upper"] = @(self.faceliveInstance.riskLabel.risk_age_upper);
    data[@"risk_action"] = @(self.faceliveInstance.riskLabel.risk_action);
#endif

    if (self.params) {
        data[@"liveness_timeout"] = self.params[@"liveness_timeout"];
        data[@"motion_types"] = self.params[@"motion_types"];
    }
    NSDictionary *dict = @{
        @"sdk_data" : [FaceLiveUtils buildFaceCompareSDKDataWithParams:data],
        @"image_env" : b64FaceWithEnv,
        @"image_face" : b64Face,
    };
    return dict;
}

- (NSString *)packLogData {
    [self.faceliveInstance saveErrorLog];
    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                                                 self.faceliveInstance.logBuffer, @"log",
                                                                 nil];
    if (self.faceliveInstance.livenessImageData != nullptr) {
        NSString *b64FaceWithLiveness = [self.faceliveInstance.livenessImageData base64EncodedStringWithOptions:0];
        data[@"image_liveness"] = b64FaceWithLiveness;
    }
    if (self.faceliveInstance.verifyOriImageData != nullptr) {
        NSString *b64Verify = [self.faceliveInstance.verifyOriImageData base64EncodedStringWithOptions:0];
        data[@"image_verify_ori"] = b64Verify;
    }
    if (self.faceliveInstance.verifyImageData != nullptr) {
        NSString *b64Verify = [self.faceliveInstance.verifyImageData base64EncodedStringWithOptions:0];
        data[@"image_verify"] = b64Verify;
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
    NSString *sdkDataVersion = newCryptType ? @"4.0" : @"3.0";
    int verStrLen = (int)[sdkDataVersion length];

    NSMutableString *sdkStr = [[NSMutableString alloc] init];
    [sdkStr appendString:[NSString stringWithFormat:@"%c", verStrLen]];
    [sdkStr appendString:sdkDataVersion];
    [sdkStr appendString:cryptStr];

    return [sdkStr copy];
}

- (void)clearTimer {
    //  self->_timeCount = 0;
    //self.countDownTimeRemaind = self.livenessTimeout;
    if (_ui_timer) {
        [_ui_timer invalidate];
        _ui_timer = nil;
    }
}

- (void)uiUpdate:(NSTimer *)theTimer {
    if (self.faceVC.bdct_flow.context.liveDetectionOpt) {
        //动画已添加
    } else {
        CGFloat progress;
        self.countDownTimeRemaind -= UI_INTERVAL;
        progress = self.countDownTimeRemaind / (self.lastMachineStage == 0 ? 20 : (self.livenessTimeout - 1));
        self.faceVC.circleProgressTrackLayer.strokeEnd = MIN(1.0, progress);
    }
}

- (void)trackCancel {
    if (self.isDetecting && self.logMode) {
        NSData *sdkData = [[self packLogData] dataUsingEncoding:NSUTF8StringEncoding];
        [self.faceVC.bdct_flow.apiService bytedfaceFailUpload:nil sdkData:sdkData completion:nil];
    }
    [self.faceVC.bdct_flow.eventTracker trackReturnPreviousPageFromPosition:@"detection"];
}

- (int)getAlgoErrorCode {
    return _faceliveInstance.algoErrorCode;
}

- (int)setRandom:(int)action_num {
    return [self.faceliveInstance setRandom:action_num];
}

- (void)setMaskRadiusRatio:(float)maskRadiusRadio offsetToCenterRatio:(float)offsetToCenterRatio {
    [_faceliveInstance setMaskRadiusRatio:maskRadiusRadio offsetToCenterRatio:offsetToCenterRatio];
}

@end
