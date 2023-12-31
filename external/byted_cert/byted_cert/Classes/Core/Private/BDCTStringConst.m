//
//  BytedCertDisplayStringHelper.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/3/9.
//

#import "BDCTStringConst.h"
#import "BDCTLocalization.h"
#import "BytedCertError.h"
#import <ByteDanceKit/NSArray+BTDAdditions.h>

NSString *const BytedCertPopupAlertActionRetry = @"retry";
NSString *const BytedCertPopupAlertActionQuit = @"quit";

NSArray<NSString *> *bdct_status_strs() {
    static dispatch_once_t onceToken;
    static NSArray *STATUS_STRS;
    dispatch_once(&onceToken, ^{
        STATUS_STRS = @[ BytedCertLocalizedString(@"检测失败"),
                         BytedCertLocalizedString(@"检测中"),
                         BytedCertLocalizedString(@"请勿遮挡并直面镜头"),
                         BytedCertLocalizedString(@"请靠近点"),
                         BytedCertLocalizedString(@"请不要过快"),
                         BytedCertLocalizedString(@"请勿遮挡并直面镜头"),
                         @"",
                         BytedCertLocalizedString(@"请确认只有一张人脸"),
                         BytedCertLocalizedString(@"请保持睁眼"),
                         BytedCertLocalizedString(@"请离远点"),
                         BytedCertLocalizedString(@"请保持人脸在框内"),
                         BytedCertLocalizedString(@"请到明亮环境下"),
                         BytedCertLocalizedString(@"请不要过曝光"),
                         BytedCertLocalizedString(@"请不要张嘴"),
                         BytedCertLocalizedString(@"保证真实人脸"),
                         BytedCertLocalizedString(@"请正对屏幕") ];
    });
    return STATUS_STRS;
}

NSArray<NSString *> *bdct_circle_strs() {
    static dispatch_once_t onceToken;
    static NSArray *CICLE_STRS;
    dispatch_once(&onceToken, ^{
        CICLE_STRS = @[ @"",
                        @"",
                        BytedCertLocalizedString(@"请勿遮挡"),
                        BytedCertLocalizedString(@"请靠近点"),
                        @"",
                        BytedCertLocalizedString(@"请正对屏幕"),
                        @"",
                        BytedCertLocalizedString(@"请一人检测"),
                        @"",
                        BytedCertLocalizedString(@"请离远点"),
                        BytedCertLocalizedString(@"请露出全脸"),
                        BytedCertLocalizedString(@"光线不足"),
                        BytedCertLocalizedString(@"光线太强"),
                        @"",
                        @"",
                        BytedCertLocalizedString(@"请正对屏幕") ];
    });
    return CICLE_STRS;
}

NSArray<NSString *> *bdct_action_strs() {
    static dispatch_once_t onceToken;
    static NSArray *ACTION_STRS;
    dispatch_once(&onceToken, ^{
        ACTION_STRS = @[ BytedCertLocalizedString(@"请眨眨眼"),
                         BytedCertLocalizedString(@"请张张嘴"),
                         BytedCertLocalizedString(@"请点点头"),
                         BytedCertLocalizedString(@"请摇摇头"),
                         BytedCertLocalizedString(@"请抬头或低头"),
                         BytedCertLocalizedString(@"请向左或向右转头"),
                         BytedCertLocalizedString(@"请直面屏幕，并保持不动") ];
    });
    return ACTION_STRS;
}

NSArray<NSString *> *bdct_reflection_status_strs() {
    static dispatch_once_t onceToken;
    static NSArray *REFLECTION_STATUS_STRS;
    dispatch_once(&onceToken, ^{
        REFLECTION_STATUS_STRS = @[ @"",
                                    BytedCertLocalizedString(@"请将脸置于框内"),
                                    BytedCertLocalizedString(@"请直面屏幕"),
                                    BytedCertLocalizedString(@"请保证只有一人"),
                                    BytedCertLocalizedString(@"请勿遮挡正脸"),
                                    BytedCertLocalizedString(@"请到光线充足的地方"),
                                    BytedCertLocalizedString(@"请将脸置于框内"),
                                    @"",
                                    BytedCertLocalizedString(@"请靠近一点"),
                                    @"",
                                    BytedCertLocalizedString(@"请远离一点"),
                                    @"" ];
    });
    return REFLECTION_STATUS_STRS;
}

NSArray<NSString *> *bdct_reflection_result_strs() {
    static dispatch_once_t onceToken;
    static NSArray *REFLECTION_STATUS_STRS;
    dispatch_once(&onceToken, ^{
        REFLECTION_STATUS_STRS = @[ BytedCertLocalizedString(@"检测通过"),
                                    BytedCertLocalizedString(@"通过失败"),
                                    BytedCertLocalizedString(@"调整好位置后重试") ];
    });
    return REFLECTION_STATUS_STRS;
}

NSArray<NSString *> *bdct_video_status_strs() {
    static dispatch_once_t onceToken;
    static NSArray *VIDEO_STATUS_STRS;
    dispatch_once(&onceToken, ^{
        VIDEO_STATUS_STRS = @[ @"",
                               @"",
                               BytedCertLocalizedString(@"请勿遮挡并直面镜头"),
                               BytedCertLocalizedString(@"请靠近点"),
                               BytedCertLocalizedString(@"请不要过快"),
                               BytedCertLocalizedString(@"请勿遮挡并直面镜头"),
                               @"",
                               BytedCertLocalizedString(@"请确认只有一张人脸"),
                               BytedCertLocalizedString(@"请保持睁眼"),
                               BytedCertLocalizedString(@"请离远点"),
                               BytedCertLocalizedString(@"请保持人脸在框内"),
                               BytedCertLocalizedString(@"请到明亮环境下"),
                               BytedCertLocalizedString(@"请不要过曝光"),
                               BytedCertLocalizedString(@"请不要张嘴"),
                               BytedCertLocalizedString(@"保证真实人脸"),
                               BytedCertLocalizedString(@"请正对屏幕") ];
    });
    return VIDEO_STATUS_STRS;
}

NSArray<NSString *> *bdct_log_event_action_strs_en() {
    static dispatch_once_t onceToken;
    static NSArray *ACTION_STRS_EN;
    dispatch_once(&onceToken, ^{
        ACTION_STRS_EN = @[ @"blink",
                            @"open_mouth",
                            @"nod",
                            @"shake_head",
                            @"up_down",
                            @"left_right" ];
    });
    return ACTION_STRS_EN;
}

NSArray<NSString *> *bdct_log_event_action_liveness_fail_reasons() {
    static dispatch_once_t onceToken;
    static NSArray *failReasons;
    dispatch_once(&onceToken, ^{
        failReasons = @[ @"检测尚未完成",
                         @"检测成功",
                         @"超时未检测到第一张有效人脸",
                         @"单个动作超时",
                         @"人脸丢失超过最大允许次数",
                         @"人脸REID超时",
                         @"做错动作，可能是视频攻击",
                         @"静默活体检测失败",
                         @"过程中人脸不一致",
                         @"请正对手机后再次认证" ];
    });
    return failReasons;
}

NSDictionary<NSNumber *, NSString *> *bdct_error_code_to_message() {
    static dispatch_once_t onceToken;
    static NSDictionary *messages;
    dispatch_once(&onceToken, ^{
        messages = @{
            @(BytedCertErrorServer) : BytedCertLocalizedString(@"网络异常，请稍后再试"),
            @(BytedCertErrorUnknown) : BytedCertLocalizedString(@"网络异常，请稍后再试"),
            @(BytedCertErrorInterruption) : BytedCertLocalizedString(@"网络异常，请稍后再试"),
            @(BytedCertErrorLiveness) : BytedCertLocalizedString(@"活体识别失败，请再试一次"),
            @(BytedCertErrorAlgorithmInitFailure) : BytedCertLocalizedString(@"网络异常，请稍后再试"),
            @(BytedCertErrorAlgorithmParamsFailure) : BytedCertLocalizedString(@"网络异常，请稍后再试"),
            @(BytedCertErrorClickCancel) : BytedCertLocalizedString(@"用户取消操作"),
            @(BytedCertErrorAlertCancel) : @"",
            @(BytedCertErrorArgs) : BytedCertLocalizedString(@"网络异常，请稍后再试"),
            @(BytedCertErrorCameraPermission) : BytedCertLocalizedString(@"无法使用相机，请检查是否打开相机权限"),
            @(BytedCertErrorNoDownload) : BytedCertLocalizedString(@"离线模型未下载"),
            @(BytedCertErrorNoModel) : BytedCertLocalizedString(@"对应模型不存在"),
            @(BytedCertErrorModelMd5) : BytedCertLocalizedString(@"模型校验失败"),
            @(BytedCertErrorVerifyFailrure) : BytedCertLocalizedString(@"比对不通过")
        };
    });
    return messages;
}

NSDictionary<NSNumber *, NSString *> *bdct_log_event_video_liveness_fail_reasons() {
    static dispatch_once_t onceToken;
    static NSDictionary *failReasons;
    dispatch_once(&onceToken, ^{
        failReasons = @{
            @(BytedCertErrorFaceQualityOverTime) : @"人脸质量检测超时",
            @(BytedCertErrorInterruptionLimit) : @"中断次数超过限制",
            @(BytedCertErrorServer) : @"视频上传失败",
            @(BytedCertErrorVideoLivenessFailure) : @"活体未通过",
            @(BytedCertErrorVideoVerifyFailrure) : @"人脸比对未通过"
        };
    });
    return failReasons;
}

NSArray<NSString *> *bdct_offline_model_pre() {
    static dispatch_once_t onceToken;
    static NSArray *OFFLINE_MODEL_PRE;
    dispatch_once(&onceToken, ^{
        OFFLINE_MODEL_PRE = @[ @"tt_offline_face_v11.1", @"tt_faceverify_v7.0", @"tt_stillliveness_mask_v2.3" ];
    });
    return OFFLINE_MODEL_PRE;
}

NSArray<NSString *> *bdct_reflection_model_pre() {
    static dispatch_once_t onceToken;
    static NSArray *REFLECTION_MODEL_PRE;
    dispatch_once(&onceToken, ^{
        REFLECTION_MODEL_PRE = @[ @"tt_reflection_v", @"tt_liveness_v" ];
    });
    return REFLECTION_MODEL_PRE;
}

NSArray<NSString *> *bdct_audio_resource_pre() {
    static dispatch_once_t onceToken;
    static NSArray *AUDIO_RESOURCE_PRE;
    dispatch_once(&onceToken, ^{
        AUDIO_RESOURCE_PRE = @[ @"当前环境光线太亮",
                                @"请保持人脸在框内",
                                @"请到明亮环境下",
                                @"请靠近点",
                                @"请确认只有一张人脸",
                                @"请勿遮挡并直面镜头",
                                @"请远离点",
                                @"请正对屏幕",
                                @"请点点头",
                                @"请抬头或低头",
                                @"请向左或向右转头",
                                @"请摇摇头",
                                @"请眨眨眼",
                                @"请张张嘴",
                                @"请直面屏幕，并保持不动",
                                @"光线太强",
                                @"光线不足",
                                @"请露出全脸",
                                @"请勿遮挡",
                                @"请一人检测" ];
    });
    return AUDIO_RESOURCE_PRE;
}


@implementation BDCTStringConst

@end
