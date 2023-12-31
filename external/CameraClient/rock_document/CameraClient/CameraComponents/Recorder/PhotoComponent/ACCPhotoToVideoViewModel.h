//
//  ACCPhotoToVideoViewModel.h
//  CameraClient-Pods-Aweme
//
//  Created by 李辉 on 2020/4/14.
//

#import <CreationKitArch/ACCRecorderViewModel.h>

#import "ACCConfigKeyDefines.h"

#import <EffectPlatformSDK/EffectPlatform.h>
#import <EffectPlatformSDK/IESEffectModel.h>
@class AWEVideoPublishViewModel;

typedef NS_ENUM(NSUInteger, ACCPhotoToVideoStrategy) {
    ACCPhotoToVideoStrategyOnline = 0, //keep online flow.
    ACCPhotoToVideoStrategySinglePhotoToVideo, //single photo goes to video model
    ACCPhotoToVideoStrategyMultiplePhotoToVideo, //multiple photos goes to video model
    ACCPhotoToVideoStrategyAllPhotoToVideo, // both single and photo goes to video model
    ACCPhotoToVideoStrategyAllPhotoToVideoWithAiClip, //both single and photo goes to video model with ai clip support.
};

typedef void(^ACCDownloadMVModelResult)(IESEffectModel * __nullable mvEffectModel);

NS_ASSUME_NONNULL_BEGIN

@interface ACCPhotoToVideoViewModel : ACCRecorderViewModel

- (void)exportMVVideoWithPublishModel:(AWEVideoPublishViewModel *)publishModel failedBlock:(void(^)(void))failedBlock;

@end

NS_ASSUME_NONNULL_END
