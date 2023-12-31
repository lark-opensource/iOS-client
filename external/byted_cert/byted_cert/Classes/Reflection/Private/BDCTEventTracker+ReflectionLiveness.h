//
//  BDCTEventTracker+ReflectionLiveness.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/3/16.
//

#import "BDCTEventTracker.h"

NS_ASSUME_NONNULL_BEGIN


@interface BDCTEventTracker (ReflectionLiveness)

/// 人脸质量检测 face_detection_video_quality
/// /// @param success 是否成功
/// @param promptInfo video_prompt_info: 对不满足质量要求的情况及相应提示(需要按先后顺序列出)
- (void)trackReflectionLivenessDetectionColorQualityResult:(BOOL)success promptInfo:(NSArray *)promptInfo;

/// 炫彩活体校验结果 face_detection_color_result
/// @param success 成功与失败
/// @param colorPromptInfo 动作提示
/// @param colorList 色彩列表
/// @param interruptTimes 中断次数
/// @param errorCode 错误码
- (void)trackReflectionLivenessDetectionResult:(BOOL)success colorPromptInfo:(NSArray *)colorPromptInfo colorList:(NSArray *)colorList interruptTimes:(int)interruptTimes errorCode:(int)errorCode;

@end

NS_ASSUME_NONNULL_END
