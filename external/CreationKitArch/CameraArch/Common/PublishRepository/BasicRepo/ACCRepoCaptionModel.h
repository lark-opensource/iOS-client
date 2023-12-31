//
//  ACCRepoCaptionModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/24.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEStudioCaptionInfoModel;


typedef NS_ENUM(NSInteger, AWEStudioCaptionQueryStatus) {
    AWEStudioCaptionQueryStatusUpload = 0,
    AWEStudioCaptionQueryStatusCommit = 1,
    AWEStudioCaptionQueryStatusQuery  = 2,
};

typedef void(^AudioQueryCompletion)(NSArray *_Nullable captionsArray, NSError *_Nullable error);

@interface ACCRepoCaptionModel : NSObject <ACCRepositoryContextProtocol, NSCopying>

@property (nonatomic, copy) NSURL *mixAudioUrl;

@property (nonatomic, copy) NSString *mixAudioInfoMd5;

- (BOOL)audioDidChanged;

- (void)resetAudioChangeFlag;

- (NSString *)currentMixAudioInfoMd5;

@end

@interface AWEVideoPublishViewModel (RepoCaption)
 
@property (nonatomic, strong, readonly) ACCRepoCaptionModel *repoCaption;
 
@end

NS_ASSUME_NONNULL_END
