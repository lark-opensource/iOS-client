//
//  BDCTEventTracker+LivenessDetectionFlow.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/3/18.
//

#import "BDCTEventTracker.h"

@class BDCTFaceVerificationFlow;

NS_ASSUME_NONNULL_BEGIN


@interface BDCTEventTracker (FaceVerificationFlow)

/// 上报活体识别的耗时
/// @param flow 活体识别节点时间记录
/// @param error 错误
- (void)trackLivenessDetectionFlowComplete:(BDCTFaceVerificationFlow *)flow error:(BytedCertError *)error;

@end

NS_ASSUME_NONNULL_END
