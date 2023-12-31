//
//  BDCTEventTracker.m
//  Pods
//
//  Created by xunianqiang on 2020/6/8.
//

#import "BDCTEventTracker.h"
#import "BytedCertInterface.h"
#import "BytedCertWrapper.h"
#import "BytedCertError.h"
#import "BDCTFaceVerificationFlow.h"
#import "BDCTFaceVerificationFlow+Tracker.h"
#import "BytedCertNetResponse.h"
#import "BytedCertManager+Private.h"
#import "BDCTLog.h"
#import "BDCTFlowContext.h"
#import "FaceLiveUtils.h"

#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <BDTrackerProtocol/BDTrackerProtocol.h>


@implementation BytedCertError (Tracker)

+ (NSString *)trackErrorCodeForError:(BytedCertError *)error {
    return [@(error.detailErrorCode ?: error.errorCode ?:
                                                         0) stringValue];
}

+ (NSString *)trackErrorMsgForError:(BytedCertError *)error {
    return error.detailErrorMessage ?: error.errorMessage ?:
                                                            @"";
}

@end


@implementation BDCTEventTracker

- (void)trackReturnPreviousPageFromPosition:(NSString *)position {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:position forKey:@"back_position"];
    [self trackWithEvent:@"return_previous_page" params:[params copy]];
}

- (void)trackFaceDetectionStart {
    [self trackWithEvent:@"face_detection_start" params:nil];
}

- (void)trackFaceDetectionPromptWithPromptInfo:(NSArray *)promptInfos result:(BytedCertTrackerPromptInfoType)result {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    // "prompt_info(需要按先后顺序列出):
    // 101: 检测失败
    // 102: 检测成功
    // 103: 请勿遮挡并直面镜头
    // 104: 请靠近点
    // 105: 请不要过快
    // 106: 请保持端正…
    // 107:
    // 108: 请趣儿只有一张人脸
    // 109: 请保持睁眼
    // 110: 请离远点
    // 111: 请保持人脸在框内
    // 112: 请在明亮环境下完成操作
    // 113: 避免强光
    // 114: 请不要张嘴
    // 115: 本帧静默无效
    [params setValue:[promptInfos btd_jsonStringEncoded] forKey:@"prompt_info"];
    [params setValue:[@(result) stringValue] forKey:@"prompt_result"];
    [self trackWithEvent:@"face_detection_prompt" params:[params copy]];
}

- (void)trackFaceDetectionImageResult:(BytedCertTrackerFaceImageType)type {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:@(type) forKey:@"result"];
    [self trackWithEvent:@"face_detection_image_result" params:[params copy]];
}

- (void)trackFaceFailImageResult:(BytedCertTrackerFaceFailImageType)type {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:@(type) forKey:@"result"];
    [self trackWithEvent:@"face_fail_image_upload_result" params:[params copy]];
}

- (void)trackFaceDetectionFinalResult:(BytedCertError *)error params:(NSDictionary *)params {
    NSMutableDictionary *mutableParams = [[NSMutableDictionary alloc] initWithDictionary:params];
    mutableParams[@"result"] = error ? @"fail" : @"success";
    mutableParams[@"fail_reason"] = [BytedCertError trackErrorMsgForError:error];
    mutableParams[@"error_code"] = @(error.errorCode);
    mutableParams[@"full_flow_timestamp"] = self.bdct_flow.performance.timeStampParams.copy;
    [self trackWithEvent:@"face_detection_final_result" params:mutableParams.copy];
}

- (void)trackFaceDetectionSDKResult:(NSDictionary *)result {
    [self trackWithEvent:@"face_detection_sdk_return" params:result];
}

- (void)trackFaceDetectionVoiceGuideCheck:(NSDictionary *)params {
    NSMutableDictionary *mutableParams = [[NSMutableDictionary alloc] init];
    mutableParams[@"result"] = ![params btd_boolValueForKey:@"error_code"] ? @"success" : @"fail";
    [mutableParams addEntriesFromDictionary:params];

    [self trackWithEvent:@"face_detection_voice_guide_check" params:mutableParams.copy];
}

/// 照片拍摄，点击时间
- (void)trackCardPhotoUpdateAlertClick:(NSString *)clickType {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:clickType forKey:@"button"];
    [self trackWithEvent:@"id_card_photo_upload_alert_click" params:[params copy]];
}

- (void)trackFaceDetectionStartCheck {
    [self trackWithEvent:@"face_detection_start_check" params:nil];
}

- (void)trackFaceDetectionStartCameraPermit:(BOOL)hasPermission {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSString *permitStr = hasPermission ? @"has_permission" : @"no_permission";
    [params setValue:permitStr forKey:@"camera_permit"];
    [self trackWithEvent:@"face_detection_camera_permit" params:[params copy]];
}

- (void)trackManualDetectionCameraPermit:(BOOL)hasPermission {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSString *permitStr = hasPermission ? @"has_permission" : @"no_permission";
    [params setValue:permitStr forKey:@"camera_permit"];
    [self trackWithEvent:@"manual_detection_camera_permit" params:[params copy]];
}

- (void)trackFaceDetectionStartWebReq:(BOOL)isSuccess {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSString *result = isSuccess ? @"web_req_success" : @"web_req_fail";
    [params setValue:result forKey:@"web_req_result"];
    [self trackWithEvent:@"face_detection_start_web_req" params:[params copy]];
}

- (void)trackIdCardPhotoUploadSelectFinish {
    [self trackWithEvent:@"id_card_photo_upload_select_finish" params:nil];
}

- (void)trackIdCardPhotoUploadCameraButton {
    [self trackWithEvent:@"id_card_photo_upload_camera_button" params:nil];
}

- (void)trackFaceDetectionFailPopupWithActionType:(NSString *)actionType failReason:(NSString *)failReason errorCode:(NSInteger)errorCode {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:actionType forKey:@"action_type"];
    [params setValue:failReason forKey:@"fail_reason"];
    [params setValue:@(errorCode) forKey:@"error_code"];
    [self trackWithEvent:@"face_detection_fail_popup" params:params.copy];
}

+ (void)trackError:(BytedCertError *)error {
    if (!error) {
        return;
    }
    NSMutableDictionary *errorInfo = [NSMutableDictionary dictionary];
    [errorInfo setValue:@"" forKey:@"exception_stack_trace"];
    [errorInfo setValue:[BytedCertError trackErrorCodeForError:error] forKey:@"error_code"];
    [errorInfo setValue:[BytedCertError trackErrorMsgForError:error] forKey:@"exception_msg"];
    [self trackWithEvent:@"byted_cert_sdk_exception" params:[errorInfo copy]];
}

- (void)trackAuthVerifyStart {
    [self trackWithEvent:@"auth_verify_start" params:@{@"phase" : @"start"}];
}

- (void)trackOfflineVerifyStart {
    [self trackWithEvent:@"offline_verify_start" params:nil];
}

- (void)trackOfflineLivenessSuccess {
    [self trackWithEvent:@"offline_liveness_success" params:nil];
}

- (void)trackAuthVerifyEndWithErrorCode:(int)errorCode errorMsg:(NSString *)errorMsg result:(NSDictionary *)result {
    NSMutableDictionary *jsbResult = [result mutableCopy];
    NSMutableDictionary *extraData = [jsbResult btd_dictionaryValueForKey:@"ext_data"].mutableCopy;
    if (extraData) {
        [extraData removeObjectForKey:@"idNumber"];
        [extraData removeObjectForKey:@"name"];
        [jsbResult btd_setObject:extraData.copy forKey:@"ext_data"];
    }
    NSDictionary *resultExtData = extraData.copy;

    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    mutableParams[@"is_finish"] = @([resultExtData btd_boolValueForKey:@"is_finish"] ? 1 : 0);
    mutableParams[@"all_module"] = [resultExtData btd_stringValueForKey:@"all_module"];
    mutableParams[@"result"] = (errorCode == 0) ? @"success" : @"fail";
    mutableParams[@"fail_reason"] = errorMsg;
    mutableParams[@"error_code"] = @(errorCode);
    mutableParams[@"full_flow_timestamp"] = self.bdct_flow.performance.timeStampParams.copy;
    [self trackWithEvent:@"auth_verify_end" params:mutableParams.copy];

    // 上报JSB返回的结果
    NSMutableDictionary *mutableResult = [jsbResult mutableCopy] ?: [NSMutableDictionary dictionary];
    [mutableResult addEntriesFromDictionary:resultExtData];
    [self trackWithEvent:@"byted_cert_certification_jsb_result" params:mutableResult.copy];
}

- (void)trackWithEvent:(NSString *)event error:(NSError *)error {
    NSMutableDictionary *errorInfo = [NSMutableDictionary dictionary];
    errorInfo[@"error_code"] = @(error.code);
    errorInfo[@"error_msg"] = error.localizedDescription ?: error.description;
    [self trackWithEvent:event params:errorInfo.copy];
}

- (void)trackBytedCertStartWithStartTime:(NSDate *)startTime response:(BytedCertNetResponse *)response error:(BytedCertError *)error {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:(error ? @(0) : @(1)) forKey:@"result"];
    NSInteger during = NSDate.date.timeIntervalSince1970 * 1000 - startTime.timeIntervalSince1970 * 1000;
    [params setValue:@(during) forKey:@"duration"];
    [params setValue:@(error.detailErrorCode ?: error.errorCode ?:
                                                                  0)
              forKey:@"error_code"];
    [params setValue:(error.detailErrorMessage ?: error.errorMessage ?:
                                                                       @"")
              forKey:@"fail_reason"];
    [params setValue:response.logId forKey:@"log_id"];
    [self trackWithEvent:@"auth_sdk_init_handler" params:params.copy];
}

- (void)trackWithEvent:(NSString *)event params:(NSDictionary *_Nullable)params {
    if (!event.length) {
        return;
    }

    BDCTLogInfo(@"New event comes from Native: event[%@], params: %@", event, params);

    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionaryWithDictionary:(params ?: @{})];
    mutableParams[@"scene"] = self.context.parameter.scene;
    mutableParams[@"mode"] = @(self.context.parameter.mode).stringValue;
    mutableParams[@"ticket"] = self.context.parameter.ticket;
    mutableParams[@"verify_source"] = self.context.finalVerifyChannel;
    mutableParams[@"flow"] = self.context.parameter.flow;
    mutableParams[@"auth_version"] = self.context.backendAuthVersion;
    mutableParams[@"extra"] = [self.context.parameter.eventParams btd_jsonStringEncoded];
    mutableParams[@"voice_guide_server"] = @(self.context.voiceGuideServer);
    mutableParams[@"voice_guide_user"] = @(self.context.voiceGuideUser);

    if (self.context.isOffline) {
        mutableParams[@"is_offline"] = @(self.context.isOffline ? 1 : 0);
    }
    if (![mutableParams btd_stringValueForKey:@"verify_detection_type"].length) {
        mutableParams[@"verify_detection_type"] = self.context.finalLivenessType ?: self.context.parameter.livenessType;
    }
    if (self.context.parameter.youthCertScene != -1) {
        mutableParams[@"age_larger_14"] = @(self.context.parameter.youthCertScene);
    }

    if (self.context.serverEventParams) {
        [mutableParams addEntriesFromDictionary:self.context.serverEventParams];
    }

    [BDCTEventTracker trackWithEvent:event params:mutableParams.copy];
}

+ (void)trackNetRequestWithStartTime:(NSDate *)startTime path:(NSString *)path response:(BytedCertNetResponse *)response error:(NSError *)error {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:(error ? @(0) : @(1)) forKey:@"result"];
    NSInteger during = NSDate.date.timeIntervalSince1970 * 1000 - startTime.timeIntervalSince1970 * 1000;
    [params setValue:@(during) forKey:@"duration"];
    [params setValue:@(error.code) forKey:@"error_code"];
    [params setValue:(error.description ?: @"") forKey:@"fail_reason"];
    [params setValue:path forKey:@"url_path"];
    [params setValue:response.logId forKey:@"log_id"];
    [self trackWithEvent:@"auth_sdk_network_request" params:params.copy];
}

+ (void)trackWithEvent:(NSString *)event params:(NSDictionary *)params {
    if (!event.length) {
        return;
    }

    BDCTLogInfo(@"New event comes from Native: event[%@], params: %@", event, params);

    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionaryWithDictionary:(params ?: @{})];
    mutableParams[@"app_id"] = BytedCertManager.aid;
    mutableParams[@"module"] = @""; // two_factor/二要素、three factor/三要素、ocr/图片识别二要素、live_detection/活体检测、face_identify/人脸比对、manual/人工认证、parent/ 监护人认证、overseas/海外流程、status/认证状态页、result/成人认证结果
    mutableParams[@"last_module"] = @"";
    mutableParams[@"sdk_version"] = BytedCertSDKVersion;
    mutableParams[@"byted_cert_sdk_version"] = BytedCertSDKVersion;
    mutableParams[@"smash_live_model_name"] = [FaceLiveUtils smashLiveModelName];
    mutableParams[@"smash_sdk_version"] = [FaceLiveUtils smashSdkVersion];
    mutableParams[@"params_for_special"] = @"uc_login";
    BytedCertInterface *bytedIf = [BytedCertInterface sharedInstance];
    if ([bytedIf.BytedCertTrackEventDelegate respondsToSelector:@selector(trackWithEvent:params:)]) {
        [bytedIf.BytedCertTrackEventDelegate trackWithEvent:event params:mutableParams.copy];
    } else {
        [BDTrackerProtocol eventV3:event params:mutableParams.copy];
    }
}

@end
