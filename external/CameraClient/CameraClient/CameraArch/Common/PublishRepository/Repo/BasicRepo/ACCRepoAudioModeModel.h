//
//  ACCRepoAudioModeModel.h
//  CameraClient-Pods-AwemeCore
//
//  Created by liujinze on 2021/10/29.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/AWEStudioCaptionModel.h>
#import <CameraClient/ACCEditVideoData.h>
#import "ACCEditMVModel.h"

@interface ACCRepoAudioModeModel : NSObject <NSCopying, ACCRepositoryRequestParamsProtocol, ACCRepositoryContextProtocol>

@property (nonatomic, assign) BOOL isAudioMode;
@property (nonatomic, copy, nullable) NSArray<NSString *> *materialPaths; // 素材的路径
@property (nonatomic, copy, nullable) NSString *audioMvId; // 语音模式的模板id
@property (nonatomic, copy, nullable) NSString *bgaudioAssetPath; // 音频文件的路径
@property (nonatomic, strong, nullable) ACCEditMVModel *mvModel;
@property (nonatomic, copy) NSArray<AWEStudioCaptionModel *> * _Nullable captions;

- (void)generateMVFromDraftVideoData:(ACCEditVideoData *)videoData
                              taskId:(NSString *)taskId
                          completion:(void(^)(ACCEditVideoData *_Nullable, NSError *_Nullable))completion;

@end

@interface AWEVideoPublishViewModel (RepoAudioMode)
 
@property (nonatomic, strong, readonly, nullable) ACCRepoAudioModeModel *repoAudioMode;
 
@end
