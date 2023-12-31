//
//  ACCRepoAuthorityModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/13.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCAwemeModelProtocol.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>


NS_ASSUME_NONNULL_BEGIN

@interface ACCRepoAuthorityModel : NSObject <NSCopying, ACCRepositoryRequestParamsProtocol>

@property (nonatomic, assign) NSInteger itemComment;

@property (nonatomic, assign) NSInteger itemDownload;
@property (nonatomic, strong) NSNumber *itemDuet;
@property (nonatomic, strong) NSNumber *itemReact;

@property (nonatomic, assign) ACCPrivacyType privacyType;
@property (nonatomic, readonly) BOOL isPrivate;

@end

@interface AWEVideoPublishViewModel (RepoAuthority)

@property (nonatomic, strong, readonly) ACCRepoAuthorityModel *repoAuthority;

@end

NS_ASSUME_NONNULL_END
