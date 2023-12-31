//
//  BDCTEventTracker+ActionLiveness.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/3/18.
//

#import "BDCTEventTracker.h"

NS_ASSUME_NONNULL_BEGIN


@interface BDCTEventTracker (ActionLiveness)

- (void)trackActionFaceDetectionLiveResult:(NSNumber *_Nullable)errorCode motionList:(NSString *)motionList promptInfos:(NSArray *)promptInfos;

@end

NS_ASSUME_NONNULL_END
