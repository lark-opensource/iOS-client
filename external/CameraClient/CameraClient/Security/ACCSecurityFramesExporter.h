//
//  ACCSecurityFramesExporter.h
//  AWEStudioService-Pods-Aweme
//
//  Created by lixingdong on 2021/3/31.
//

#import <Foundation/Foundation.h>
#import <TTVideoEditor/HTSVideoData.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCSecurityFramesExporter : NSObject

// export video frames to upload
+ (void)exportVideoFramesWithPublishModel:(AWEVideoPublishViewModel *)publishModel
                                  awemeId:(NSString *)awemeId
                               completion:(void (^)(NSArray *framePaths, NSError *error))completion;

// export custom sticker frames to upload
+ (void)exportCustomStickerFramesWithPublishModel:(AWEVideoPublishViewModel *)publishModel
                                       completion:(void (^)(NSArray *framePaths, NSError *error))completion;

// export props asset frames to upload
+ (void)exportPropsFramesWithPropsAssets:(NSArray<AVAsset *> *)videoAssets
                           clipDurations:(NSMutableArray<NSNumber *> *)clipDurations
                            publishModel:(AWEVideoPublishViewModel *)publishModel
                              completion:(void (^)(NSArray *framePaths, NSError *error))completion;

+ (void)exportPropsFramesWithPublishModel:(AWEVideoPublishViewModel *)publishModel
                               completion:(void (^)(NSArray *framePaths, NSError *error))completion;

@end

NS_ASSUME_NONNULL_END
