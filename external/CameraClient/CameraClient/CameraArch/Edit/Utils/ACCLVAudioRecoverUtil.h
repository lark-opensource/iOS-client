//
//  ACCLVAudioRecoverUtil.h
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2020/12/29.
//

#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreationKitArch/ACCRepoFlowControlModel.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;

@interface ACCLVAudioRecoverUtil : NSObject

+ (void)recoverAudioIfNeededWithOption:(ACCLVFrameRecoverOption)option publishModel:(AWEVideoPublishViewModel *)publishModel editService:(id<ACCEditServiceProtocol>)editService;

@end

NS_ASSUME_NONNULL_END
