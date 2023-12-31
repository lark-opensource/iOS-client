//
//  ACCRepoRearResourceModel.h
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/4/8.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>


NS_ASSUME_NONNULL_BEGIN

@interface ACCRepoRearResourceModel : NSObject

@property (nonatomic, copy, nullable) NSArray <NSString *> *stickerIDArray;
@property (nonatomic, strong, nullable) id<ACCMusicModelProtocol> musicModel;
@property (nonatomic, copy, nullable) NSString *gradeKey;
@property (nonatomic, assign) BOOL shouldStopLoadWhenfetchMusicError;
@property (nonatomic, copy, nullable) NSString *musicSelectFrom;
@property (nonatomic, copy, nullable) NSString *musicSelectPageName;
@property (nonatomic, copy, nullable) NSString *propSelectFrom;

@end

@interface AWEVideoPublishViewModel (RepoRearResource)
 
@property (nonatomic, strong, readonly) ACCRepoRearResourceModel *RepoRearResource;
 
@end

NS_ASSUME_NONNULL_END
