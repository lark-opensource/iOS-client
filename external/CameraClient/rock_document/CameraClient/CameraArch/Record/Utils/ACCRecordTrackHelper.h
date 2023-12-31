//
//  ACCRecordTrackHelper.h
//  Pods
//
//  Created by songxiangwu on 2019/8/19.
//

#import <Foundation/Foundation.h>
#import <TTVideoEditor/VERecorder.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCCameraService;

@interface ACCRecordTrackHelper : NSObject

+ (NSDictionary *)trackAttributesOfPhotoFeatureWithCamera:(id<ACCCameraService>)camera publishModel:(AWEVideoPublishViewModel *)publishModel;
+ (NSDictionary *)trackAttributesFromDictionary:(NSDictionary *)dict publishModel:(AWEVideoPublishViewModel *)publishModel;

@end

NS_ASSUME_NONNULL_END
