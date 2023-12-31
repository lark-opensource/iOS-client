//
//  BDCTEventTracker+VideoLiveness.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/3/16.
//

#import "BDCTEventTracker.h"

@class BytedCertError;

NS_ASSUME_NONNULL_BEGIN


@interface BDCTEventTracker (VideoLiveness)

/// 人脸质量检测 face_detection_video_quality
/// /// @param success 是否成功
/// @param promptInfo video_prompt_info: 对不满足质量要求的情况及相应提示(需要按先后顺序列出)
- (void)trackVideoLivenessDetectionFaceQualityResult:(BOOL)success promptInfo:(NSArray *)promptInfo;

/// 视频活体校验结果 face_detection_video_result
/// @param readNumber 读数
/// @param interuptTimes 中断次数
/// @param error error
- (void)trackVideoLivenessDetectionResultWithReadNumber:(NSString *)readNumber interuptTimes:(int)interuptTimes error:(BytedCertError *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
