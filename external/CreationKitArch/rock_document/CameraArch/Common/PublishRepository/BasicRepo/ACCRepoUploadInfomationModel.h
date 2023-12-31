//
//  ACCRepoUploadInfomationModel.h
//  CameraClient
//
//  Created by haoyipeng on 2020/10/22.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/ACCStudioDefines.h>
#import <CreationKitArch/AWEVideoPublishViewModelDefine.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEAssetModel;

@interface ACCRepoUploadInfomationModel : NSObject <NSCopying, ACCRepositoryRequestParamsProtocol, ACCRepositoryContextProtocol>

@property (nonatomic, strong) NSMutableDictionary *extraDict;
@property (nonatomic, assign) BOOL isSpeedChange;
@property (nonatomic, assign) NSTimeInterval exportTime;
@property (nonatomic, assign) AWEVideoClipMode videoClipMode;
@property (nonatomic, strong) NSNumber *originUploadVideoClipCount;
@property (nonatomic, strong) NSNumber *originUploadPhotoCount;
@property (nonatomic, assign) AWEAIVideoClipSourceType clipSourceType;
@property (nonatomic, assign) BOOL isMultiVideoUpload;
@property (nonatomic, assign) AWEAssetModelMediaSubType mediaSubType;
// the first video originated from faceu, include single and multi videos
@property (nonatomic, assign) BOOL isFaceuVideoFirst;
@property (nonatomic, strong, nullable) UIImage *toBeUploadedImage;
// the first video originated from faceu, include single and multi videos
@property (nonatomic, strong) NSMutableArray <AWEVideoPublishSourceInfo *> *sourceInfos;
@property (nonatomic, copy) NSArray<AWEAssetModel *> *selectedUploadAssets;

- (BOOL)isAIVideoClipMode;

- (nullable NSArray *)sourceInfosArray;


@end

@interface AWEVideoPublishViewModel (RepoUploadInfo)
 
@property (nonatomic, strong, readonly) ACCRepoUploadInfomationModel *repoUploadInfo;
 
@end

NS_ASSUME_NONNULL_END
