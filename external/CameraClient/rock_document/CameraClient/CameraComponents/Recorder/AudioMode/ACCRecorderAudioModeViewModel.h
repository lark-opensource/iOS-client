//
//  ACCRecorderAudioModeViewModel.h
//  CameraClient-Pods-AwemeCore
//
//  Created by liujinze on 2021/10/21.
//

#import <CreationKitArch/ACCRecorderViewModel.h>
#import <CameraClient/ACCEditVideoData.h>
#import <CreationKitArch/AWEStudioCaptionModel.h>
#import "ACCAudioModeService.h"

@class ACCEditMVModel, AWEVideoPublishViewModel;

@interface ACCRecorderAudioModeViewModel : ACCRecorderViewModel<ACCAudioModeService>

@property (nonatomic, strong, readonly, nullable) ACCEditVideoData *resultVideoData;
@property (nonatomic, strong, readonly, nullable) ACCEditMVModel *resultMVModel;
@property (nonatomic, strong, readonly, nullable) NSMutableArray<AWEStudioCaptionModel *> *resultCaptions;
@property (nonatomic, strong, readonly, nullable) UIImage *userAvatarImage;

- (void)prefetchAudioMVTemplate;

- (void)preFetchAvatarImage:(void(^)(void))completion;

- (ACCEditMVModel *)generateAudioMVDataWithImages:(NSArray * _Nullable)images
                                       repository:(AWEVideoPublishViewModel *  _Nullable)repository
                                      draftFolder:(NSString *  _Nullable)draftFolder
                                        videoData:(ACCEditVideoData *  _Nullable)videoData
                                       completion:(void(^)(ACCEditVideoData *  _Nullable, NSError *  _Nullable))completion;

- (void)updateAudioCaptions:(NSMutableArray<AWEStudioCaptionModel *> *  _Nullable)captions;

- (void)send_audioModeVCDidAppearSignal;

@end
