//
//  AWERepoUploadInfomationModel.h
//  CameraClient
//
//  Created by haoyipeng on 2020/10/22.
//

#import <CreationKitArch/ACCRepoUploadInfomationModel.h>


NS_ASSUME_NONNULL_BEGIN

@interface AWERepoUploadInfomationModel : ACCRepoUploadInfomationModel <NSCopying, ACCRepositoryRequestParamsProtocol, ACCRepositoryContextProtocol, ACCRepositoryTrackContextProtocol>

// only for draft
@property (nonatomic, copy) NSString *uploadImagePath;
@property (nonatomic, copy, nullable) NSString *uploadImagePathRelative;
@property (nonatomic, strong, nullable) NSString *sourceInfoJson;
@property (nonatomic, strong, nullable) NSData *extraDictData;

// Lynx内流容器ID
@property (nonatomic, copy) NSString *reactID;

- (BOOL)isShootEnterFromGroot;

- (void)updateImageSourceInfoIfNeeded;

@end

@interface AWEVideoPublishViewModel (AWERepoUploadInfo)
 
@property (nonatomic, strong, readonly) AWERepoUploadInfomationModel *repoUploadInfo;
 
@end

NS_ASSUME_NONNULL_END
