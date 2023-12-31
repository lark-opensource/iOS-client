//
//  AWEAudioModeDataHelper.h
//  CameraClient-Pods-AwemeCore
//
//  Created by liujinze on 2021/11/4.
//

#import <Foundation/Foundation.h>
#import <CameraClient/ACCEditVideoData.h>

@class ACCEditMVModel,AWEVideoPublishViewModel,IESEffectModel;
@interface AWEAudioModeDataHelper : NSObject

+ (void)prefetchAudioMVTemplate:(void(^)(BOOL success, IESEffectModel *templateModel))completion;

+ (ACCEditMVModel *)generateAudioMVDataWithImages:(NSArray *)images
                                    templateModel:(IESEffectModel *)model
                                       repository:(AWEVideoPublishViewModel *)repository
                                      draftFolder:(NSString *)draftFolder
                                        videoData:(ACCEditVideoData *)videoData
                                       completion:(void(^)(ACCEditVideoData *, NSError *))completion;

+ (NSString *)outputBgAudioAsset:(AVAsset *)asset withDraftID:(NSString *)taskID;

@end
