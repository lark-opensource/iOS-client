//
//  AWERepoAuthorityModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/13.
//

#import <CreationKitArch/ACCRepoAuthorityModel.h>

NS_ASSUME_NONNULL_BEGIN

@class AWERepoAuthorityContext;

// publish exclusion
@interface AWEVideoDraftExclusionModel : NSObject <NSCoding, NSCopying>

@property (nonatomic, assign) BOOL isHideSearch;
@property (nonatomic, copy) NSArray *exclusionSecUidList;
@property (nonatomic, copy) NSString *exclusionListJson; //array json string
@property (nonatomic, assign) BOOL isExclusionSelected;
@property (nonatomic, assign) BOOL enablePublishExclusion;
@property (nonatomic, copy) NSArray *exclusionUserList;

- (BOOL)isEqualToObject:(AWEVideoDraftExclusionModel *)object;

@end


@interface AWERepoAuthorityModel : ACCRepoAuthorityModel<ACCRepositoryContextProtocol>

@property (nonatomic, strong) AWEVideoDraftExclusionModel *exclusionModel;

@property (nonatomic, assign) BOOL shouldShowGrant;

@property (nonatomic, strong) NSNumber *downloadType; // 视频下载权限，0可以下载，3不可以下载
/** 分享到日常权限 */
@property (nonatomic, strong) NSNumber *itemShare;

@property (nonatomic, strong) AWERepoAuthorityContext *authorityContext;

- (BOOL)isEqualToObject:(AWERepoAuthorityModel *)object;

@end

@interface AWEVideoPublishViewModel (AWERepoAuthority)

@property (nonatomic, strong, readonly) AWERepoAuthorityModel *repoAuthority;

@end

NS_ASSUME_NONNULL_END
